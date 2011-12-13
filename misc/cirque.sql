CREATE TABLE cirque_installation (
    id VARCHAR(255) NOT NULL PRIMARY KEY, 
    value VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE sessions (
    id  CHAR(72) PRIMARY KEY,
    session_data TEXT
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_servicer (
    id CHAR(32) NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    api_key CHAR(12) NOT NULL UNIQUE,
    api_secret CHAR(40) NOT NULL UNIQUE,
    created_on DATETIME DEFAULT '0000-00-00 00:00:00',
    modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_project (
    id CHAR(36) NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    slug VARCHAR(255) NOT NULL,
    description TEXT,
    enable_email TINYINT(1) NOT NULL DEFAULT 1,
    default_assignment VARCHAR(255),
    created_on DATETIME DEFAULT '0000-00-00 00:00:00',
    modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY (slug)
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_project_member (
    id CHAR(36) NOT NULL PRIMARY KEY,
    project_id CHAR(36) NOT NULL,
    account_id VARCHAR(255) NOT NULL,
    UNIQUE KEY (project_id, account_id),
    FOREIGN KEY (project_id) REFERENCES cirque_project (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_milestone (
    id BIGINT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    project_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    due_on DATETIME,
    created_on DATETIME DEFAULT '0000-00-00 00:00:00',
    modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY (project_id, name),
    FOREIGN KEY (project_id) REFERENCES cirque_project (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_repository (
    id CHAR(36) NOT NULL PRIMARY KEY,
    project_id CHAR(36) NOT NULL,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    link_pattern TEXT,
    created_on DATETIME DEFAULT '0000-00-00 00:00:00',
    modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES cirque_project (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_branch (
    id CHAR(36) NOT NULL PRIMARY KEY,
    repository_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    sha1 CHAR(40) NOT NULL,
    is_head TINYINT NOT NULL DEFAULT 0,
    created_on DATETIME DEFAULT '0000-00-00 00:00:00',
    modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY (repository_id, name, is_head),
    FOREIGN KEY (repository_id) REFERENCES cirque_repository (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_project_history (
    id BIGINT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    project_id CHAR(36) NOT NULL,
    
    FOREIGN KEY (project_id) REFERENCES cirque_project (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_result (
    id CHAR(36) NOT NULL PRIMARY KEY,
    output TEXT NOT NULL,
    created_on DATETIME NOT NULL,
    modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_issue (
    id BIGINT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    project_id  CHAR(36) NOT NULL,
    resolution  ENUM( 'open', 'in-progress', 'verify-fixed', 'fixed', 'wontfix', 'dup', 'closed' ) NOT NULL DEFAULT 'open',
    author      VARCHAR(255) NOT NULL,
    title       TEXT NOT NULL,
    target      VARCHAR(255),
    issue_type  VARCHAR(32) NOT NULL,
    severity    ENUM('critical', 'major', 'minor', 'nitpick', 'wishlist' ) NOT NULL DEFAULT 'major',
    assigned_to VARCHAR(255),
    version     VARCHAR(255),
    milestone_id BIGINT,
    description TEXT NOT NULL,
    due_on DATETIME,
    cc TEXT,
    created_on DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY (resolution),
    KEY (author),
    FOREIGN KEY (project_id) REFERENCES cirque_project (id) ON DELETE CASCADE,
    /* milestone cannot be removed unless it's taken out completely */
    FOREIGN KEY (milestone_id) REFERENCES cirque_milestone (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_issue_action (
    id BIGINT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    project_id   CHAR(36) NOT NULL,
    issue_id     BIGINT NOT NULL,
    commit_id    CHAR(40),
    author       VARCHAR(255) NOT NULL,
    action       VARCHAR(32) NOT NULL,
    message      TEXT,
    reference    VARCHAR(255),
    metadata     TEXT,
    created_on DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (issue_id) REFERENCES cirque_issue (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_issue_summary_by_project (
    project_id     CHAR(36) NOT NULL PRIMARY KEY,
    total_open     INT NOT NULL DEFAULT 0,
    total_critical INT NOT NULL DEFAULT 0,
    total_major    INT NOT NULL DEFAULT 0,
    total_minor    INT NOT NULL DEFAULT 0,
    total_nitpick  INT NOT NULL DEFAULT 0,
    total_wishlist INT NOT NULL DEFAULT 0,
    created_on     DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    FOREIGN KEY (project_id) REFERENCES cirque_project (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_issue_summary_history (
    id BIGINT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    project_id CHAR(36) NOT NULL,
    total_open     INT NOT NULL DEFAULT 0,
    total_critical INT NOT NULL DEFAULT 0,
    total_major    INT NOT NULL DEFAULT 0,
    total_minor    INT NOT NULL DEFAULT 0,
    total_nitpick  INT NOT NULL DEFAULT 0,
    total_wishlist INT NOT NULL DEFAULT 0,
    created_on     DATETIME NOT NULL,
    logged_on      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES cirque_project (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_issue_comment (
    id BIGINT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    project_id   CHAR(36) NOT NULL,
    issue_id     BIGINT NOT NULL,
    author       VARCHAR(255) NOT NULL,
    body        TEXT NOT NULL,
    created_on DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (issue_id) REFERENCES cirque_issue (id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES cirque_project (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_issue_attachment (
    id BIGINT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    project_id   CHAR(36) NOT NULL,
    issue_id     BIGINT NOT NULL,
    author       VARCHAR(255) NOT NULL,
    filename     VARCHAR(64) NOT NULL,
    mimetype     VARCHAR(64) NOT NULL,
    filesize BIGINT NOT NULL,
    body MEDIUMBLOB NOT NULL,
    created_on DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    modified_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (issue_id) REFERENCES cirque_issue (id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES cirque_project (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_issue_relation (
    id BIGINT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    issue_id BIGINT NOT NULL,
    parent_issue_id BIGINT NOT NULL,
    FOREIGN KEY (issue_id) REFERENCES cirque_issue (id) ON DELETE CASCADE,
    FOREIGN KEY (parent_issue_id) REFERENCES cirque_issue (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_saved_query (
    id BIGINT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    account_id VARCHAR(255) NOT NULL,
    query      TEXT NOT NULL, /* should be json */
    sequence INT NOT NULL DEFAULT 0,
    KEY (account_id)
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_issue_keyword (
    id BIGINT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    issue_id BIGINT NOT NULL,
    keyword VARCHAR(255) NOT NULL,
    key (issue_id, keyword),
    FOREIGN KEY (issue_id) REFERENCES cirque_issue (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_user (
    id INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    account_id VARCHAR(255) NOT NULL,
    name VARCHAR(128) NOT NULL,
    icon VARCHAR(255) NOT NULL,
    KEY (account_id)
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

CREATE TABLE cirque_user_notify_checked (
    id BIGINT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    account_id VARCHAR(255) NOT NULL UNIQUE,
    notify_checked DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
    FOREIGN KEY (account_id) REFERENCES cirque_user (account_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARACTER SET 'utf8';

DELIMITER $$
CREATE TRIGGER cirque_project_before_insert_trig
    BEFORE INSERT ON cirque_project
    FOR EACH ROW BEGIN
        SET NEW.created_on = NOW();
        SET NEW.modified_on = NOW();
    END
$$

CREATE TRIGGER cirque_milestone_before_insert_trig
    BEFORE INSERT ON cirque_milestone
    FOR EACH ROW BEGIN
        SET NEW.created_on = NOW();
        SET NEW.modified_on = NOW();
    END
$$

CREATE TRIGGER cirque_repository_before_insert_trig
    BEFORE INSERT ON cirque_repository
    FOR EACH ROW BEGIN
        SET NEW.created_on = NOW();
        SET NEW.modified_on = NOW();
    END
$$

CREATE TRIGGER cirque_issue_before_insert_trig
    BEFORE INSERT ON cirque_issue
    FOR EACH ROW BEGIN
        SET NEW.created_on = NOW();
        SET NEW.modified_on = NOW();
    END
$$

CREATE TRIGGER cirque_issue_before_update_trig
    BEFORE UPDATE ON cirque_issue
    FOR EACH ROW BEGIN
        SET NEW.modified_on = NOW();
    END
$$

CREATE TRIGGER cirque_issue_attachment_before_insert_trig
    BEFORE INSERT ON cirque_issue_attachment
    FOR EACH ROW BEGIN
        SET NEW.created_on = NOW();
        SET NEW.modified_on = NOW();
    END
$$

CREATE PROCEDURE compile_issue_summary_for_project (x_project_id CHAR(36))
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE 
            x_count,
            x_total_critical,
            x_total_major,
            x_total_minor,
            x_total_nitpick,
            x_total_wishlist INT DEFAULT 0;
    DECLARE x_name TEXT;
    DECLARE cur1 CURSOR FOR
        SELECT severity, count(*) FROM cirque_issue
            WHERE project_id = x_project_id AND
                  resolution = 'open'
            GROUP BY severity;
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

    OPEN cur1;

    REPEAT
        FETCH cur1 INTO x_name, x_count;
        IF NOT done THEN
            CASE x_name
                WHEN 'critical' THEN
                    SET x_total_critical = x_count;
                WHEN 'major' THEN
                    SET x_total_major = x_count;
                WHEN 'minor' THEN
                    SET x_total_minor = x_count;
                WHEN 'nitpick' THEN
                    SET x_total_nitpick = x_count;
                WHEN 'wishlist' THEN
                    SET x_total_wishlist = x_count;
            END CASE;
        END IF;
    UNTIL done END REPEAT;
    CLOSE cur1;

    REPLACE INTO cirque_issue_summary_by_project
        ( project_id, total_open, total_critical, total_major, total_minor, total_nitpick, total_wishlist )
        VALUES
        ( x_project_id,
            x_total_critical + x_total_major + x_total_minor + x_total_nitpick + x_total_wishlist,
            x_total_critical,
            x_total_major,
            x_total_minor,
            x_total_nitpick,
            x_total_wishlist
        )
    ;
END
$$

CREATE PROCEDURE copy_issue_summary_to_history (x_project_id CHAR(36))
BEGIN
    INSERT INTO cirque_issue_summary_history 
        ( project_id, total_open, total_critical, total_major, total_minor, total_nitpick, total_wishlist, created_on )
        SELECT project_id, total_open, total_critical, total_major, total_minor, total_nitpick, total_wishlist, created_on 
        FROM cirque_issue_summary_by_project 
        WHERE project_id = x_project_id 
    ;
END
$$

CREATE PROCEDURE update_issue_keyword ( x_issue_id BIGINT )
BEGIN
    DECLARE x_keyword TEXT DEFAULT '';
    DECLARE x_issue_exists INT;

    SELECT CONCAT_WS( ' ',
        project.name, milestone.name, issue.title, 
        issue.resolution, issue.author, issue.severity, 
        issue.created_on, issue.modified_on, issue.description
    )  INTO x_keyword
    FROM cirque_issue AS issue
    LEFT OUTER JOIN cirque_project AS project ON issue.project_id = project.id 
    LEFT OUTER JOIN cirque_milestone AS milestone ON issue.milestone_id = milestone.id 
    WHERE issue.id = x_issue_id;


    SELECT 1 INTO x_issue_exists FROM cirque_issue_keyword WHERE issue_id = x_issue_id;
    IF ( x_issue_exists ) THEN 
        UPDATE cirque_issue_keyword
            SET keyword = x_keyword
            WHERE issue_id = x_issue_id
        ;
    ELSE
        INSERT INTO cirque_issue_keyword (issue_id, keyword)
            VALUES ( x_issue_id, x_keyword )
        ;
    END IF;
END
$$

CREATE TRIGGER cirque_issue_after_insert_trig
    AFTER INSERT ON cirque_issue
    FOR EACH ROW BEGIN
        CALL update_issue_keyword( NEW.id );
        CALL compile_issue_summary_for_project(NEW.project_id);
    END
$$

CREATE TRIGGER cirque_issue_after_update_trig
    AFTER UPDATE ON cirque_issue
    FOR EACH ROW BEGIN
        CALL update_issue_keyword( NEW.id );
        CALL compile_issue_summary_for_project(NEW.project_id);
    END
$$

CREATE TRIGGER cirque_issue_after_delete_trig
    AFTER DELETE ON cirque_issue
    FOR EACH ROW BEGIN
        CALL compile_issue_summary_for_project(OLD.project_id);
    END
$$

CREATE TRIGGER cirque_servicer_before_insert_trig
    BEFORE INSERT ON cirque_servicer
    FOR EACH ROW BEGIN
        SET NEW.created_on = NOW();
        SET NEW.modified_on = NOW();
    END
$$

CREATE TRIGGER cirque_issue_action_before_insert_trig
    BEFORE INSERT ON cirque_issue_action
    FOR EACH ROW BEGIN
        SET NEW.created_on = NOW();
        SET NEW.modified_on = NOW();
    END
$$

CREATE TRIGGER cirque_issue_comment_before_insert_trig
    BEFORE INSERT ON cirque_issue_comment
    FOR EACH ROW BEGIN
        SET NEW.created_on = NOW();
        SET NEW.modified_on = NOW();
    END
$$

CREATE TRIGGER cirque_issue_comment_before_update_trig
    BEFORE UPDATE ON cirque_issue_comment
    FOR EACH ROW BEGIN
        SET NEW.modified_on = NOW();
    END
$$

CREATE TRIGGER cirque_issue_summary_by_project_before_insert_trig
    BEFORE INSERT ON cirque_issue_summary_by_project
    FOR EACH ROW BEGIN
        SET NEW.created_on = NOW();
    END
$$

CREATE TRIGGER cirque_issue_summary_by_project_after_insert_trig
    AFTER INSERT ON cirque_issue_summary_by_project
    FOR EACH ROW BEGIN
        CALL copy_issue_summary_to_history(NEW.project_id);
    END
$$

CREATE TRIGGER cirque_issue_summary_history_before_insert_trig
    BEFORE INSERT ON cirque_issue_summary_history
    FOR EACH ROW BEGIN
        SET NEW.created_on = NOW();
    END
$$

CREATE TRIGGER cirque_saved_query_before_insert_trig
    BEFORE INSERT ON cirque_saved_query
    FOR EACH ROW BEGIN
        DECLARE max_sequence INT DEFAULT 0;
        DECLARE cur1 CURSOR FOR
            SELECT max(sequence) FROM cirque_saved_query
            WHERE account_id = NEW.account_id
        ;
        OPEN cur1;
        FETCH cur1 INTO max_sequence;
        CLOSE cur1;
        IF max_sequence IS NULL THEN
             SET max_sequence = -1;
        END IF;
        SET NEW.sequence = max_sequence + 1;
    END
$$

CREATE TRIGGER cirque_user_after_insert_trig
    AFTER INSERT ON cirque_user
    FOR EACH ROW BEGIN
        INSERT INTO cirque_user_notify_checked ( account_id )
        VALUES ( NEW.account_id );
    END
$$

DELIMITER ;
