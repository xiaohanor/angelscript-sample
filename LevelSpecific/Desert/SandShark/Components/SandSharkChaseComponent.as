enum ESandSharkChaseState
{
	None,
	Diving,
	Ground,
	Air
}

UCLASS(Abstract)
class USandSharkChaseComponent : UActorComponent
{
	ESandSharkChaseState State = ESandSharkChaseState::None;
	ASandShark SandShark;

	bool bIsChasing = false;

	float DiveActiveDuration = 0;

	FVector ChaseTargetLocation;

	float DurationBeforeCanMove = SandShark::Animations::DiveDuration;

	bool bCanMoveDuringDive = false;

	float DistanceToTarget = MAX_flt;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SandShark = Cast<ASandShark>(Owner);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(SandShark).Section("Chase");

		TemporalLog.Value(f"ChaseDiveActiveDuration", DiveActiveDuration);
		TemporalLog.Value(f"State", State);
		TemporalLog.Sphere(f"ChaseTargetLocation", ChaseTargetLocation, 20, FLinearColor::Yellow, 10);
	}
#endif

	void StartChase()
	{
		bIsChasing = true;
		SandShark.bCanAttack = true;
	}

	void EndChase()
	{
		bIsChasing = false;
		SandShark.bCanAttack = false;
	}
};