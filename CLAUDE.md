# HospitalTriaje — Claude Instructions

## Agent Delegation

**Every query must be delegated to the appropriate specialized agent. The main agent must not perform any work directly.**

- Use the `Agent` tool for all tasks: research, exploration, planning, coding, testing, etc.
- Select the correct `subagent_type` based on the task (e.g., `Explore` for codebase search, `Plan` for architecture, `general-purpose` for implementation).
- The main agent's only role is to receive the user's request, dispatch it to the right agent, and relay the result back to the user.
