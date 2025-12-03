UCLASS(Abstract)
class UDarkMassEventHandler : UHazeEffectEventHandler
{

	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UDarkMassUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserComp = UDarkMassUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Created() { }
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Destroyed() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Attached(FDarkMassSurfaceData SurfaceData) { }
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Detached(FDarkMassSurfaceData SurfaceData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Grab(FDarkMassGrabData GrabData) { }
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Release(FDarkMassGrabData GrabData) { }

	UFUNCTION(BlueprintCallable)
	void CalculateTentacleLocation(FVector&out StartLocation,
		FVector&out StartTangentLocation,
		FVector&out EndLocation,
		FVector&out EndTangentLocation,
		int Index) const
	{
		StartLocation = GetStartLocation(Index);
		StartTangentLocation = GetStartTangent(Index) + StartLocation;
		EndLocation = GetEndLocation(Index);
		EndTangentLocation = GetEndTangent(Index) + EndLocation;
	}

	UFUNCTION(BlueprintPure)
	FVector GetStartLocation(int Index) const
	{
		return UserComp.MassActor.ActorLocation;
	}

	UFUNCTION(BlueprintPure)
	FVector GetStartTangent(int Index) const
	{
		return FVector::ZeroVector;
	}

	UFUNCTION(BlueprintPure)
	FVector GetEndLocation(int Index) const
	{
		if (Index < 0 || Index > UserComp.MassActor.CurrentGrabs.Num() - 1)
			return UserComp.MassActor.ActorLocation;

		return UserComp.MassActor.CurrentGrabs[Index].WorldLocation;
	}

	UFUNCTION(BlueprintPure)
	FVector GetEndTangent(int Index) const
	{
		return FVector::ZeroVector;
	}

	UFUNCTION(BlueprintPure)
	ADarkMassActor GetDarkMass() const
	{
		return UserComp.MassActor;
	}

	UFUNCTION(BlueprintPure)
	int GetMaxGrabs() const
	{
		return DarkMass::MaxGrabs;
	}
}