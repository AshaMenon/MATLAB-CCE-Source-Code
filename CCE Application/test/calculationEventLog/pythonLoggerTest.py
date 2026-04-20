# -*- coding: utf-8 -*-
"""
CCELogger Tests
"""

import unittest
import os
import sys

class LoggerTest(unittest.TestCase):
    msg_param2 = (12, 'string')
    msg_param1 = "Test with number %d placeholder of %s"

    
    def setUp(self):
        filepath = os.path.abspath("../../cce/pythonLogger/cce_logger.py")
        filepath = filepath[:-14]
        if filepath not in sys.path:
            sys.path.append(filepath)
            
        self.log_dir = "CCE_Calc_Log"
        self.file_name1 = "test1.log"
        self.file_name_no_cat = "testNoCat.log"
        self.msg_fmt1 = "Test with number %d placeholder of %s"
        #self.mgs_arg1 = [12, "some string"]
        
    def test_logger_constructor1_arg(self):
        import logger
        import log_message_level as lg
        path1 = os.path.join(self.log_dir, self.file_name1)
        logger1 = logger.Logger(path1)
        self.assertIsInstance(logger1, logger.Logger)
        self.assertEqual(logger1._Logger__log_file_path, path1)
        self.assertEqual(logger1._Logger__category, "")
        self.assertEqual(logger1._Logger__unique_id, "None")
        self.assertEqual(logger1._Logger__log_level, lg.LogMessageLevel.ALL)
        
        # Defining a relative path should throw a warning
        path2 = self.file_name1
        logger2 = logger.Logger(path2)
        with self.assertWarns(UserWarning):
            logger.Logger(path2)
        self.assertEqual(logger2._Logger__log_file_path, os.path.join(os.getcwd(), path2));
        
    def test_logger_constructor2_arg(self):
          import logger
          import log_message_level as lg
          path1 = os.path.join(self.log_dir, self.file_name1)
          cat1 = "cat1"
          logger1 = logger.Logger(path1, cat1)
          self.assertIsInstance(logger1, logger.Logger)
          self.assertEqual(logger1._Logger__log_file_path, path1)
          self.assertEqual(logger1._Logger__category, "cat1")
          self.assertEqual(logger1._Logger__unique_id, "None")
          self.assertEqual(logger1._Logger__log_level, lg.LogMessageLevel.ALL)

    def test_logger_constructor3_arg(self):
          import logger
          import log_message_level as lg
          path1 = os.path.join(self.log_dir, self.file_name1)
          cat1 = "cat1"
          my_id = "Id";
          logger1 = logger.Logger(path1, cat1, my_id)
          self.assertIsInstance(logger1, logger.Logger)
          self.assertEqual(logger1._Logger__log_file_path, path1)
          self.assertEqual(logger1._Logger__category, "cat1")
          self.assertEqual(logger1._Logger__unique_id, my_id)
          self.assertEqual(logger1._Logger__log_level, lg.LogMessageLevel.ALL)          
    
    def test_logger_constructor4_arg(self):
          import logger
          import log_message_level as lg
          path1 = os.path.join(self.log_dir, self.file_name1)
          cat1 = "cat1"
          my_id = "Id";

          for enum in lg.LogMessageLevel:
            #Check the enumeration itself as an argument
            l = logger.Logger(path1, cat1, my_id, enum)
            self.assertEqual(l._Logger__log_level, enum)
            #Check that the string version also works
            l = logger.Logger(path1, cat1, my_id, enum.value)
            self.assertEqual(l._Logger__log_level, enum)
            #Check that the integer version also works
            l = logger.Logger(path1, cat1, my_id, enum.name)
            self.assertEqual(l._Logger__log_level, enum)
            
            
    def test_log_info(self):
            #Test that logging and messages with different formats work.
            #   This is a parameterised test. We sweep across 3 different message formats (MsgParams) and across
            #   all the available log write levels (logInfo, logWarning, logError, etc.)
            #
            #   Note that if this combination gets too large, so does the eventual log file.
            import logger
            f_path = os.path.join(self.log_dir, self.file_name1)
            cat_str = "Cat1"
            id_str = "ID"
            log = logger.Logger(f_path, cat_str, id_str, "ALL")
            log.log_info(self.msg_param1, *self.msg_param2)
            # Now read the file back
            f = open(f_path, "r")
            txt = f.readlines()
            f.close()
            msg_string = self.msg_param1 %(self.msg_param2)
            final_str = "%s, %s, %s, %s" %(cat_str, id_str, 'Info', msg_string)
            self.assertEqual(txt[-1][25:-1], final_str)
            
    def test_log_error(self):
            #Test that logging and messages with different formats work.
            #   This is a parameterised test. We sweep across 3 different message formats (MsgParams) and across
            #   all the available log write levels (logInfo, logWarning, logError, etc.)
            #
            #   Note that if this combination gets too large, so does the eventual log file.
            import logger
            f_path = os.path.join(self.log_dir, self.file_name1)
            cat_str = "Cat1"
            id_str = "ID"
            log = logger.Logger(f_path, cat_str, id_str, "ALL")
            log.log_error(self.msg_param1, *self.msg_param2)
            # Now read the file back
            f = open(f_path, "r")
            txt = f.readlines()
            f.close()
            msg_string = self.msg_param1 %(self.msg_param2)
            final_str = "%s, %s, %s, %s" %(cat_str, id_str, 'Error', msg_string)
            self.assertEqual(txt[-1][25:-1], final_str)
            
    def test_log_debug(self):
            #Test that logging and messages with different formats work.
            #   This is a parameterised test. We sweep across 3 different message formats (MsgParams) and across
            #   all the available log write levels (logInfo, logWarning, logError, etc.)
            #
            #   Note that if this combination gets too large, so does the eventual log file.
            import logger
            f_path = os.path.join(self.log_dir, self.file_name1)
            cat_str = "Cat1"
            id_str = "ID"
            log = logger.Logger(f_path, cat_str, id_str, "ALL")
            log.log_debug(self.msg_param1, *self.msg_param2)
            # Now read the file back
            f = open(f_path, "r")
            txt = f.readlines()
            f.close()
            msg_string = self.msg_param1 %(self.msg_param2)
            final_str = "%s, %s, %s, %s" %(cat_str, id_str, 'Debug', msg_string)
            self.assertEqual(txt[-1][25:-1], final_str)
            
    def test_log_warning(self):
            #Test that logging and messages with different formats work.
            #   This is a parameterised test. We sweep across 3 different message formats (MsgParams) and across
            #   all the available log write levels (logInfo, logWarning, logError, etc.)
            #
            #   Note that if this combination gets too large, so does the eventual log file.
            import logger
            f_path = os.path.join(self.log_dir, self.file_name1)
            cat_str = "Cat1"
            id_str = "ID"
            log = logger.Logger(f_path, cat_str, id_str, "ALL")
            log.log_warning(self.msg_param1, *self.msg_param2)
            # Now read the file back
            f = open(f_path, "r")
            txt = f.readlines()
            f.close()
            msg_string = self.msg_param1 %(self.msg_param2)
            final_str = "%s, %s, %s, %s" %(cat_str, id_str, 'Warning', msg_string)
            self.assertEqual(txt[-1][25:-1], final_str)
            
    def test_log_trace(self):
            #Test that logging and messages with different formats work.
            #   This is a parameterised test. We sweep across 3 different message formats (MsgParams) and across
            #   all the available log write levels (logInfo, logWarning, logError, etc.)
            #
            #   Note that if this combination gets too large, so does the eventual log file.
            import logger
            f_path = os.path.join(self.log_dir, self.file_name1)
            cat_str = "Cat1"
            id_str = "ID"
            log = logger.Logger(f_path, cat_str, id_str, "ALL")
            log.log_trace(self.msg_param1, *self.msg_param2)
            # Now read the file back
            f = open(f_path, "r")
            txt = f.readlines()
            f.close()
            msg_string = self.msg_param1 %(self.msg_param2)
            final_str = "%s, %s, %s, %s" %(cat_str, id_str, 'Trace', msg_string)
            self.assertEqual(txt[-1][25:-1], final_str)
            
    def test_logger_no_cat(self):
        #Check that empty category arguments skips that in the output
        import logger
        f_path = os.path.join(self.log_dir, self.file_name_no_cat)
        id_str = "ID"
        msg_str = "This is a string."
        log = logger.Logger(f_path, "", id_str, "ALL")
        log.log_info(msg_str);
        f = open(f_path, "r")
        txt = f.readlines()
        f.close()
        # We can't search for a substring, because we don't know the time this is being written.
        # Instead, count the commas.
        self.assertEqual(txt[-1].count(','), 3);
        
    def test_log_special(self):
        #Test logging of special characters
        # Try to write out a newline, and a comma, in the message format
        import logger
        f_path = os.path.join(self.log_dir, self.file_name1)
        cat_str = 'Cat'
        id_str = "ID"
        msg_str = "This is a string, with a comma."
        log = logger.Logger(f_path, cat_str, id_str, "ALL")
        log.log_info(msg_str);
        f = open(f_path, "r")
        txt = f.readlines()
        f.close()
        # We can't search for a substring, because we don't know the time this is being written.
        # Instead, count the commas.
        self.assertEqual(txt[-1].count(','), 4);

if __name__ == '__main__':
    unittest.main()   
    unittest.msg_param2 = ()
    unittest.msg_param1 = "Test with no placeholders."
    unittest.main() 
    

                                                                                 