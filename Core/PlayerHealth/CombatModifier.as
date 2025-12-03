
// Combat modifiers that the player can enable as an accessibility option
enum ECombatModifier
{
	None,
	InfiniteHealth,
}

const FConsoleVariable CVar_CombatModifier_Mio("Haze.CombatModifier_Mio", 0);
const FConsoleVariable CVar_CombatModifier_Zoe("Haze.CombatModifier_Zoe", 0);

ECombatModifier GetCombatModifier(AHazePlayerCharacter Player)
{
	if (Player.IsMio())
		return ECombatModifier(CVar_CombatModifier_Mio.GetInt());
	else
		return ECombatModifier(CVar_CombatModifier_Zoe.GetInt());
}