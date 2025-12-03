
UCLASS(Abstract)
class UWorld_Skyline_Highway_Interactable_CargoScanner_Laser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UHazeAudioComponent AudioComp;
	UPrimitiveComponent LaserCollider;
	AHazePlayerCharacter Mio;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AudioComp = DefaultEmitter.GetAudioComponent();

		// SoundDef attach should be applied as collider of laser
		LaserCollider = Cast<UPrimitiveComponent>(AudioComp.GetAttachParent());
		AudioComp.DetachFromParent();

		Mio = Game::GetMio();
		SetEmitterLocation();
	}

	UFUNCTION(BlueprintPure)
	float GetZoneLinkValue()
	{			
		return AudioComp.GetZoneOcclusion(false, nullptr, false);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		SetEmitterLocation();
	}	

	private void SetEmitterLocation()
	{
		FVector ClosestMioPos;
		LaserCollider.GetClosestPointOnCollision(Mio.GetActorLocation(), ClosestMioPos);

		AudioComp.SetWorldLocation(ClosestMioPos);	
	}
}