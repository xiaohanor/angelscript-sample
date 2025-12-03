
class UWorld_Skyline_Shared_Interactable_GravityWhip_Movable_CargoDoorLock_SoundDefAdapter : USkylineCargoDoorLockEventHandler
{

	UWorld_Skyline_Shared_Interactable_GravityWhip_Movable_SoundDef GetSoundDef() const property
	{
		return Cast<UWorld_Skyline_Shared_Interactable_GravityWhip_Movable_SoundDef>(Outer);
	}

	/* AUTO-GENERATED CODE  */

	/*On Gravity Whip Released*/
	UFUNCTION(BlueprintOverride)
	void OnGravityWhipReleased()
	{
		SoundDef.GravityWhipReleased();
	}

	/*On Gravity Whip Grabbed*/
	UFUNCTION(BlueprintOverride)
	void OnGravityWhipGrabbed()
	{
		SoundDef.GravityWhipGrabbed();
	}

	/*On Constrain Hit High Alpha*/
	UFUNCTION(BlueprintOverride)
	void OnConstrainHitHighAlpha(FSkylineCargoDoorLockEventConstrainHit InParams)
	{
		FGravityWhipMovableParams GravityWhipParams;
		GravityWhipParams.HitStrength = InParams.HitStrength;
		
		SoundDef.ConstrainHitHighAlpha(GravityWhipParams);
	}

	/*On Constrain Hit Low Alpha*/
	UFUNCTION(BlueprintOverride)
	void OnConstrainHitLowAlpha(FSkylineCargoDoorLockEventConstrainHit InParams)
	{
		FGravityWhipMovableParams GravityWhipParams;
		GravityWhipParams.HitStrength = InParams.HitStrength;
		
		SoundDef.ConstrainHitLowAlpha(GravityWhipParams);
	}

	/*On Stop Moving*/
	UFUNCTION(BlueprintOverride)
	void OnStopMoving()
	{
		SoundDef.StopMoving();
	}

	/*On Start Moving*/
	UFUNCTION(BlueprintOverride)
	void OnStartMoving()
	{
		SoundDef.StartMoving();
	}

	/* END OF AUTO-GENERATED CODE */

}