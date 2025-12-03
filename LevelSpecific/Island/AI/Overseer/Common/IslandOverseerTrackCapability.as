
class UIslandOverseerTrackCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AAIIslandOverseer Overseer;
	float Offset;
	float TrackSpeed = 0.05;
	FVector PreviousLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Overseer = Cast<AAIIslandOverseer>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousLocation = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Delta = PreviousLocation - Owner.ActorLocation;
		float DeltaSize = Delta.Size();

		if(DeltaSize < SMALL_NUMBER)
			return;

		PreviousLocation = Owner.ActorLocation;

		if(Owner.ActorForwardVector.DotProduct(PreviousLocation - Owner.ActorLocation) > 0)
		{
			Offset -= DeltaSize * TrackSpeed * DeltaTime;
			if(Offset < 0)
				Offset = 1+Offset;
		}
		else
		{
			Offset += DeltaSize * TrackSpeed * DeltaTime;
			if(Offset > 1)
				Offset = Offset-1;
		}

		Overseer.Mesh.SetScalarParameterValueOnMaterialIndex(2, n"OffsetX", -Offset);
	}
}