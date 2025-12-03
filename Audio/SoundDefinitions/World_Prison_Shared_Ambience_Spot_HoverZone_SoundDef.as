
UCLASS(Abstract)
class UWorld_Prison_Shared_Ambience_Spot_HoverZone_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnDisabled(){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerExit(FSwarmDroneHoverZonePlayerParams ExitParams){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerEnter(FSwarmDroneHoverZonePlayerParams EnterParams){}

	UFUNCTION(BlueprintEvent)
	void SwarmDroneHoveringStart(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable, Category = "Emitters")
	UHazeAudioEmitter WindEmitter;	

	private ADroneSwarmHoverZone HoverZone;
	UStaticMeshComponent FanMesh;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		HoverZone = Cast<ADroneSwarmHoverZone>(HazeOwner);
		FanMesh = UStaticMeshComponent::Get(HoverZone, n"fan");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HoverZone == nullptr)
			return false;

		return HoverZone.bZoneEnabled;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !HoverZone.bZoneEnabled;
	}

	UFUNCTION(BlueprintCallable)
	void SetClosestWindPlayerPosition()
	{
		AHazePlayerCharacter ClosestPlayer = WindEmitter.AudioComponent.GetClosestPlayer();	
		if(ClosestPlayer == nullptr)
			return;
			
		FVector ClosestWindPos = HoverZone.GetClosestVerticalPointOnHoverZone(ClosestPlayer.GetActorLocation());

		WindEmitter.GetAudioComponent().SetWorldLocation(ClosestWindPos);
	}

	UFUNCTION(BlueprintPure)
	float GetSwarmDroneHoverZoneVerticalDistance()
	{
		auto VerticalPos = HoverZone.GetClosestVerticalPointOnHoverZone(Game::GetMio().GetActorLocation());
		float DistToFan = Math::Abs(Math::Min(0, (FanMesh.WorldLocation.Z - VerticalPos.Z)));

		const float VerticalDistNormalized =  Math::GetMappedRangeValueClamped(FVector2D(355, 800), FVector2D(0.0, 1.0), DistToFan);
		return VerticalDistNormalized;
	}
}