DO $$
-- Set initial sequence to a large number to test the entire toolchain
-- works on integers with higher bits set.
DECLARE
    quoted_name text;
    quoted_size text;
BEGIN
    -- Find the name of the relevant sequence.
    --
    -- pg_get_serial_sequence quotes identifiers as part of its
    -- behavior.
    SELECT name
    INTO STRICT quoted_name
    FROM pg_get_serial_sequence('queue_classic_jobs', 'id') AS name;

    -- Don't quote, because ALTER SEQUENCE RESTART doesn't like
    -- general literals, only unquoted numeric literals.
    SELECT pow(2, 34)::text AS size
    INTO STRICT quoted_size;

    EXECUTE 'ALTER SEQUENCE ' || quoted_name ||
        ' RESTART ' || quoted_size || ';';
END;
$$;

