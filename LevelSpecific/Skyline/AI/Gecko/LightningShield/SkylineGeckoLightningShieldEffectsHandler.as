UCLASS(Abstract)
class USkylineGeckoLightningShieldEffectsHandler : UHazeEffectEventHandler
{
	USkylineGeckoSettings Settings;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly)
	TArray<FName> EmitterSockets;
	default EmitterSockets.Add(n"LeftForeArm");
	default EmitterSockets.Add(n"RightForeArm");
	default EmitterSockets.Add(n"LeftLeg");
	default EmitterSockets.Add(n"RightLeg");

	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(Transient, BlueprintReadWrite, NotVisible)
	TArray<UNiagaraComponent> Arcs;

	TArray<FVector> ArcEnds;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USkylineGeckoSettings::GetSettings(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
	}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnActivate() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeactivate() {}

	UFUNCTION(BlueprintCallable)
	void UpdateArcs(float DeltaTime)
	{
		FVector VelocityOffset = Owner.ActorVelocity * 0.25;
		float ArcReach = 200.0;
		int iEnd = 0;
		for (UNiagaraComponent Arc : Arcs)
		{
			Arc.SetVectorParameter(n"Start", Arc.WorldLocation);

			if (!ArcEnds.IsValidIndex(iEnd) || !ArcEnds[iEnd].IsWithinDist(Arc.WorldLocation + VelocityOffset, ArcReach * 2.0))
			{
				// Move arc end (or create a new one)
				FVector StartOffset = (Arc.WorldLocation - Owner.ActorLocation);
				FVector StartDir = StartOffset.ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
				FVector EndLoc = Arc.WorldLocation + VelocityOffset + StartDir * ArcReach - StartOffset.ProjectOnTo(Owner.ActorUpVector) * 1.2;
				ArcEnds.Insert(EndLoc, iEnd);
			}
			Arc.SetVectorParameter(n"End", ArcEnds[iEnd]);
			iEnd++;
		}
	}
}
