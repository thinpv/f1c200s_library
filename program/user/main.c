#include <task.h>

rt_thread_t thread[THREAD_NUM];

int main(void)
{
  thread[0] = rt_thread_create("BUZZER",
                               BUZZER_task,
                               RT_NULL,
                               BUZZER_Thread_StackSize,
                               BUZZER_Thread_Priority,
                               BUZZER_Thread_Tick);
  rt_thread_startup(thread[0]);

  thread[2] = rt_thread_create("LCD",
                               LCD_task,
                               RT_NULL,
                               LCD_Thread_StackSize,
                               LCD_Thread_Priority,
                               LCD_Thread_Tick);
  rt_thread_startup(thread[2]);
}
