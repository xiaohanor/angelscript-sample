UCLASS(NotBlueprintable)
class USkylineBossLegComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossLeg> LegClass;

	UPROPERTY(EditDefaultsOnly)
	const ESkylineBossLeg LegIndex = ESkylineBossLeg::Left;

	ASkylineBossLeg Leg;
	USkylineBossFootTargetComponent FootTargetComponent;
	
	FVector PlacementForward;
	bool bIsGrounded = true;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Leg == nullptr)
			return;

		if(FootTargetComponent == nullptr)
			return;

		FString Category;
		FTemporalLog TemporalLog = Leg.GetTemporalLog(Category);

		TemporalLog.Value(f"{Category};Leg", Leg);

		TemporalLog.Value(f"{Category};Foot Target Component", FootTargetComponent);
		TemporalLog.Arrow(f"{Category};From Foot to Target", Leg.GetFootLocation(), FootTargetComponent.WorldLocation, 100, 100000, Color = Leg.GetLegDebugColor());
		
		TemporalLog.DirectionalArrow(f"{Category};PlacementForward", Leg.GetFootLocation(), PlacementForward * 5000, 100);
		TemporalLog.Value(f"{Category};Is Grounded", bIsGrounded);
	}
#endif

	ASkylineBossLeg SpawnLeg()
	{
		check(Leg == nullptr);

		Leg = SpawnActor(LegClass, bDeferredSpawn = true);
		Leg.Boss = Cast<ASkylineBoss>(Owner);
		Leg.OwningLegComp = this;
		Leg.MakeNetworked(this, int(LegIndex));

#if EDITOR
		Leg.SetActorLabel(f"Leg {LegIndex:n}");
#endif

		FinishSpawningActor(Leg);

		Leg.AttachToComponent(Leg.Boss.Mesh, Leg.Boss.GetMeshSocketNameForFootEndBone(LegIndex));

		const FVector LocationOffset = FVector(0, 0, SkylineBoss::IK_CHAIN_END_VERTICAL_OFFSET); // FVector(0, 0, 2700)
		const FQuat RotationOffset = SkylineBoss::IK_CHAIN_END_ROTATION_OFFSET.Quaternion();
		Leg.SetActorRelativeTransform(FTransform(RotationOffset, LocationOffset));

		return Leg;
	}

	int opCmp(USkylineBossLegComponent Other) const
	{
		if(LegIndex < Other.LegIndex)
			return -1;
		else
			return 1;
	}
}