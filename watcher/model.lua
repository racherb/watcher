
-- Schema Definition for Active Watchers
local schema = {
    awatchers = {
        name = "awatcher",
        type = "record",
        fields = {
            {name="wid", type="int" },
            {name="type", type="string" },
            {name="what", type="string"},
            {name="dini", type="number"},
            {name="dend", type="number"},
            {
                name = "object",
                type = {
                    type = "record",
                    name = "object_schema",
                    fields = {
                        {name="fid", type="number"},
                        {name="answ", type="boolean"},
                        {name="mssg", type="string"},
                        {name="value", type="string"}
                    }
                }
            }
        }
    }
}

