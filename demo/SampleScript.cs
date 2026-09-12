using System;
using System.Collections.Generic;
using Godot;

namespace SyntaxHighlighterDemo
{
	// This file exists purely to show off the highlighter's coverage.
	// Open it in Godot's built-in script editor to see it in color.

	/// <summary>
	/// A grab-bag of C# constructs: keywords, built-in types, PascalCase
	/// type names, numbers, and every string flavor C# supports.
	/// </summary>
	public partial class SampleScript : Node
	{
		private const int MaxRetries = 3;
		private const float Gravity = 9.81f;
		private const double Pi = 3.14159265358979;
		private const long BigNumber = 1_000_000L;
		private const int HexValue = 0xFF00FF;

		public string PlainString = "Hello, \"world\"!\n";
		public string InterpolatedString = $"Retries left: {MaxRetries}";
		public string VerbatimString = @"C:\Users\Varrion\Documents";
		public string VerbatimMultiline = @"line one
line two
line three";
		public string RawString = """
			This is a raw string literal.
			No escaping needed for "quotes" or \backslashes\.
			""";
		public char Initial = 'V';

		[Export] public int Health { get; set; } = 100;
		[Signal] public delegate void DiedEventHandler();

		public override void _Ready()
		{
			/* Block comments
			   span multiple lines
			   just fine. */
			var items = new List<string> { "sword", "shield", "potion" };

			foreach (var item in items)
			{
				GD.Print($"Found item: {item}");
			}

			if (Health <= 0)
			{
				EmitSignal(SignalName.Died);
			}
			else if (Health < MaxRetries)
			{
				throw new InvalidOperationException("Health too low.");
			}

			for (int i = 0; i < 10; i++)
			{
				Health -= (int)(Gravity * 0.1);
			}
		}

#if TOOLS
		private void EditorOnlyHelper()
		{
			GD.Print("Running in the editor.");
		}
#endif
	}
}
