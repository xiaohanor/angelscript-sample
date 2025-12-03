namespace Perch
{

/**
 * Teleport the player so it is perching on the specified perch point.
 */
void TeleportPlayerOntoPerch(AHazePlayerCharacter Player, FInstigator Instigator, UPerchPointComponent PerchPoint)
{
	if (!Player.HasControl())
		return;

	if (PerchPoint.IsDisabledForPlayer(Player))
	{
		devError(f"Cannot teleport to perch point {PerchPoint} because it is disabled.");
		return;
	}

	auto PerchComp = UPlayerPerchComponent::Get(Player);
	if (PerchComp.Data.bPerching)
		PerchComp.StopPerching();

	PerchComp.StartPerching(PerchPoint, true);
	if (PerchPoint.bHasConnectedSpline)
	{
		PerchComp.bIsLandingOnSpline = true;
		PerchComp.Data.bInPerchSpline = true;
	}
}

}