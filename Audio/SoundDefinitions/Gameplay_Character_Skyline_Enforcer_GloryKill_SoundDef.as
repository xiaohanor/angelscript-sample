
UCLASS(Abstract)
class UGameplay_Character_Skyline_Enforcer_GloryKill_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UGravityWhipResponseComponent GravityWhipResponseComp;
	
	bool bGloryKillActive = false;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		GravityWhipResponseComp = UGravityWhipResponseComponent::Get(HazeOwner);
		GravityWhipResponseComp.OnGloryKill.AddUFunction(this, n"GloryKillStarted");
		GravityWhipResponseComp.OnGloryKillEnded.AddUFunction(this, n"GloryKillEnded");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return bGloryKillActive;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !bGloryKillActive;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bGloryKillActive = true;		
	}

	UFUNCTION(NotBlueprintCallable)
	void GloryKillStarted(UGravityWhipUserComponent UserComp, FGravityWhipActiveGloryKill GloryKill)
	{
		bGloryKillActive = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void GloryKillEnded()
	{
		bGloryKillActive = false;
	}
}