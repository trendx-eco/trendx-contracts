const networkSchema = {
  id: "/NetworkSchema",
  type: "object",
  properties: {
    url: { type: "string", required: true },
    accounts: { type: "array", item: { type: "string" } },
    overrides: { type: "object" },
  },
};

const contractSchema = {
  id: "/ContractSchema",
  type: "object",
  properties: {
    name: { type: "string", required: true },
  },
  patternProperties: {
    "^w+$": { type: "any" },
  },
};

module.exports = {
  accounts: {
    type: "array",
    items: {
      type: "string",
    },
  },
  networks: {
    type: "object",
    patternProperties: {
      "^w+$": networkSchema,
    },
  },
  contracts: {
    type: "object",
    patternProperties: {
      "^w+$": contractSchema,
    },
  },
};
