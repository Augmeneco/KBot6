import kb
from io import StringIO
import contextlib
import sys

class ExecuteCmd:
	level = 255
	keywords = ['pyexec']
	def handler(self, msg):
		import builtins
		local_globals = {'__name__': '__main__', '__doc__': None, '__package__': None, '__loader__':globals()['__loader__'], '__spec__': None, '__annotations__': {}, '__builtins__': builtins}
		#local_locals = {}
		@contextlib.contextmanager
		def stdoutIO(stdout=None):
			old = sys.stdout
			if stdout is None:
				stdout = StringIO()
			sys.stdout = stdout
			yield stdout
			sys.stdout = old

		with stdoutIO() as s:
			exec(msg['argument'], local_globals, {})

		text = s.getvalue().replace(' ', '&#160;').replace('    ', '&#8195;')
		print(kb.vkapi('messages.send',{"message":text,"peer_id":msg['peer_id']}))

kb.reg_command(ExecuteCmd())
