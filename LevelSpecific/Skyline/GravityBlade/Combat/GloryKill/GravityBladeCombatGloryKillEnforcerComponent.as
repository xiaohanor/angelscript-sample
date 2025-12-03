class UGravityBladeCombatEnforcerGloryDeathComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	bool bShouldGloryDie = false;
	
	FGravityBladeCombatGloryKillAnimData AnimData;
	float GloryDeathDuration;
	AHazePlayerCharacter KillerPlayer;

	void StartGloryDeath(int GloryDeathAnimationIndex, float Duration, AHazePlayerCharacter Player, bool bRightFootForward, bool bAirborne)
	{
		AnimData.GloryKillAnimationIndex = GloryDeathAnimationIndex;
		AnimData.LastAttackFrame = Time::FrameNumber;
		AnimData.bRightFootForward = bRightFootForward;
		AnimData.bAirborne = bAirborne;
#if TEST
		AnimData.bRightFootForward = GravityBladeGloryKillDevToggles::GetOverrideSideRight(AnimData.bRightFootForward);
#endif		

		GloryDeathDuration = Duration;
		KillerPlayer = Player;
		bShouldGloryDie = true;
	}
}