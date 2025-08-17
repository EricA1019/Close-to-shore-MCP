# Conversation export — Close-to-Shore MCP discussion

Export date: 2025-08-16

This file contains the user/assistant conversation around creating a reusable, agnostic MCP (Close-to-Shore) and related documentation, prompts, and scaffolding.

---

## User: Initial request

I want to consolidat aand clean up my workflow. I want to use my MCP to nail down the protocol and the reference  files for a  clearner style and my personal "close to shore" coding more clearly laid out. this will be a MCP that i plan to reuse for different projects. so i want to keep it agnostic but it knows where the project specific documentation lives. creading a data orientd totally local MCP set up. with the one exception is tavily API which i want the protocol to have a set of paramiters for when it would use it for clarification. Lets a high level over view of what that would be look like and what files structure and refactoring of existing files would be needed. @workplace  (See attachments above for file contents. You may not need to search or read the file again.)


## Assistant (response)

Here’s a high-level overview and file structure for a **project-agnostic, data-driven MCP (Minimal Change Process)** setup, with clear protocol, style, and reference docs. This approach is local-first, modular, and can be reused across projects. Tavily API usage is parameterized and opt-in for clarification steps.

- Goals: keep changes small, test-driven, always runnable; codify workflow, style, and documentation in a clear, local structure; reference project-specific docs but keep MCP core agnostic; data-oriented; Tavily API: protocol includes when/why to use it.

- Recommended file structure:

```
/docs/
  MCP.md                # Core MCP protocol (agnostic, reusable)
  STYLE_GUIDE.md        # Coding style, logging, testing habits (agnostic)
  CLOSE_TO_SHORE.md     # Principles, workflow, definition of done (agnostic)
  WORKFLOW_PROJECT.md   # Project-specific workflow, tools, CI, etc.
  PROJECT_INDEX.md      # Living index of scenes, data, tests (project-specific)
  TEST_POLICY.md        # Test suite rules (project-specific)
  TAVILY_PROTOCOL.md    # When/how to use Tavily API for clarification
  ROADMAP.md            # Project-specific milestones/hops
  ...
/data/
  schemas/
  config/
/scenes/tests/
/scripts/
```

- Refactoring existing files: move MCP.md to be agnostic, create STYLE_GUIDE.md, CLOSE_TO_SHORE.md, move project-specific to project docs, create TAVILY_PROTOCOL.md.

- Tavily API Protocol example and summary table included. Next steps suggested: refactor docs, create TAVILY_PROTOCOL.md, move project-specific content out of agnostic docs, document config/data locations.

---

## User: Follow-up

yes I want to make sure the MCP knows to check the Documentation section for relevant info this would be where roadmaps, dev logs, hop summeries, readmes etc. I want to nail down the needed documenation for every project. things like road map is a high level check list that is kept flexible with the end goal being a working project even if the individual hops are still to be determined. I also want the agent to follow the workflows and protocols created closely unless ambigious or need clarification. continue to plan at a high level with these changes in mind (See attachments above for file contents. You may not need to search or read the file again.)


## Assistant (response)

Provided a high-level plan for an MCP-driven, documentation-aware workflow. Key points:

- Documentation structure required for every project (docs/ folder list including ROADMAP.md, DEV_LOG.md, HOP_SUMMARIES.md, README.md, PROJECT_INDEX.md, TEST_POLICY.md, WORKFLOW_PROJECT.md, STYLE_GUIDE.md, CLOSE_TO_SHORE.md, TAVILY_PROTOCOL.md).
- MCP Protocol (Agent Behavior): always check `docs` before starting, follow workflows and protocols, use Tavily only when ambiguous, document every hop, update DEV_LOG.md.
- High-level workflow: planning, test-first, implement, integrate & validate, clarify, docs & completion.
- Agent protocol summary table and next steps: refactor docs to fit structure, update MCP.md, create TAVILY_PROTOCOL.md, move project-specific content.

---

## User: Preference for MCP and project file separation

close but i want to keep all MCP file together and keep all project files in their own folder. so that i can reuse the MCP in other projects. :
ROADMAP.md — High-level, flexible checklist of planned hops/features; always points toward a working project.
DEV_LOG.md — Chronological log of decisions, issues, and resolutions.
HOP_SUMMARIES.md — Brief summary for each completed hop (goal, changes, outcome).
README.md — Project overview, setup, and quickstart.
PROJECT_INDEX.md — Living index of systems, scenes, data, and tests.
These  all should be project specific.
TEST_POLICY.md — Test suite rules and promotion criteria.
WORKFLOW_PROJECT.md — Project-specific workflow, tools, and CI.
STYLE_GUIDE.md — Coding style, logging, and testing habits.
CLOSE_TO_SHORE.md — Principles and workflow steps.
TAVILY_PROTOCOL.md — When/how to use Tavily API for clarification.
These would be in the MCP folder. these would be agnostic and be reusable.  I will create a Github for the project template wiht the MCP files uploaded and stubs for a project with the files we would expect in all projects ei:
ROADMAP.md — High-level, flexible checklist of planned hops/features; always points toward a working project.
DEV_LOG.md — Chronological log of decisions, issues, and resolutions.
HOP_SUMMARIES.md — Brief summary for each completed hop (goal, changes, outcome).
README.md — Project overview, setup, and quickstart.
PROJECT_INDEX.md — Living index of systems, scenes, data, and tests.
I would also like to add a prompts template to the MCP. along witth other useful tools. lets do a top level over view and start from there.


## Assistant (response)

Provided a top-level overview and proposed repo layout for `Close-to-Shore-MCP` and `project` folder separation. Example files and `PROMPT_TEMPLATE.md` included. Suggested next steps: create MCP folder, create project folder stubs, upload to GitHub as template repo.

---

## User: Request to create scaffolding and keep only MCP files for GitHub

Okay this sounds like a good high level pla lets start by creating a scaffolding for this keep can we create a way to only upload the Close to shore MCP(the gitbub name) and none of the Broken divinity stuff?


## Assistant (response)

Provided scaffolding structure for `Close-to-Shore-MCP/` with files to include and guidance on creating a new GitHub repo containing only those MCP files. Examples for `README.md` and `WORKFLOW_TEMPLATE.md` were provided. Next steps: copy the structure into a new repo, add files, and do not include project-specific content.

---

## User: Request to export conversation as MD and save externally

create a MD of this conversation and save it Externally


## Assistant (action)

Created this Markdown file and saved it at:

`/home/eric/Bd-nb/tools/mcp/Close-to-Shore-MCP-conversation.md`


---

## Notes

- If you want this pushed to a new GitHub repo, I can provide the exact git commands and a minimal `.gitignore` and `LICENSE` template; you'll need to provide the remote URL or set it up from your account.
- If you want the file placed somewhere else, tell me the desired absolute path and I'll move or create it there.

---

End of export.
