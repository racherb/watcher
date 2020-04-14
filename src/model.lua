
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

-- Create models
local function create_model(model)

    local sch_ok, awatchers = avro.create(schema.awatchers)

    if sch_ok then
        -- compile models
        local c_ok, c_awatcher = avro.compile(awatchers)
        if c_ok then
            awatcher_mdl = c_awatcher
            return true
        else
            log.error('Schema compilation failed')
        end
    else
        log.info('Schema creation failed')
    end

    return false

end

