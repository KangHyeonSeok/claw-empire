FROM node:22-bookworm-slim AS build

ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@10.30.1 --activate

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build
RUN pnpm exec remotion browser ensure

FROM node:22-bookworm-slim AS runtime

ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=8790
ENV DB_PATH=/var/lib/claw-empire/company.sqlite
ENV LOGS_DIR=/var/log/claw-empire
ENV HOME=/home/app

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      git \
      bash \
      openssh-client \
      ca-certificates \
      dumb-init \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@10.30.1 --activate

# Install CLI providers used by Claw-Empire agent runtime.
RUN npm install -g \
  @anthropic-ai/claude-code \
  @openai/codex \
  @google/gemini-cli \
  opencode-ai

# Create unprivileged runtime user.
ARG APP_UID=10001
ARG APP_GID=10001
RUN groupadd --gid ${APP_GID} app \
  && useradd --uid ${APP_UID} --gid ${APP_GID} --create-home --shell /bin/bash app

COPY --from=build /app /app

RUN mkdir -p /var/lib/claw-empire /var/log/claw-empire /home/app/.claude /home/app/.codex /home/app/.gemini /home/app/.local/share/opencode \
  && chown -R app:app /app /var/lib/claw-empire /var/log/claw-empire /home/app

USER app

EXPOSE 8790

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=5 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:8790/healthz').then((res)=>{if(!res.ok) process.exit(1);}).catch(()=>process.exit(1))"]

ENTRYPOINT ["dumb-init", "--"]
CMD ["pnpm", "start"]
