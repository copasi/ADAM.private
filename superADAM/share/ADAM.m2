getenv "ADAM_ROOT"

-- Create an ADAM "task" json file, from inputs
toTask = method()
toTask(List, List, List) := (inputs, arguments, names) -> (
    toJSON new HashTable from {
        "task" => new HashTable from {
            "type" => names#0,
            "method" => new HashTable from {
                "id" => names#1,
                "description" => names#2,
                "arguments" => names#3
                },
            "input" => inputs
            }
        }
    )

-- Get parts of a task json file, as 
readTask = method()
readTask String := (json) -> (
    -- returns a hash table:
    -- inputs: a list of hashtables
    -- arguments: a list of values
    -- ...
    -- 
    )

end

restart
needsPackage "JSON"
dir = "~/src/reinhard/ADAM/superADAM/REACT/"
str = get (dir|"doc/sample-input.json")
H = parseJSON str
print prettyPrintJSON H

toTask("