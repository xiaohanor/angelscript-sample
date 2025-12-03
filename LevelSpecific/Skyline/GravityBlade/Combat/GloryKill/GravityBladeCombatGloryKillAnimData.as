struct FGravityBladeCombatGloryKillAnimData
{
	int GloryKillAnimationIndex = 0;
	uint LastAttackFrame = 0;
	bool bRightFootForward;
	bool bAirborne;

	bool WasAttackStarted() const
	{
		return (LastAttackFrame == Time::FrameNumber);
	}
}