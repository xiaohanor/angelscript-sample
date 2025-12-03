class UDarkMassUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	ADarkMassActor MassActor;

	private AHazePlayerCharacter Player;
	private UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	FDarkMassSurfaceData GetAimSurfaceData() const
	{
		auto AimResult = AimComp.GetAimingTarget(this);

		const FVector TraceStart = Math::ClosestPointOnInfiniteLine(
			AimResult.AimOrigin,
			AimResult.AimOrigin + (AimResult.AimDirection * DarkMass::AimRange),
			Player.ActorCenterLocation
		);
		const FVector TraceEnd = TraceStart + AimResult.AimDirection * DarkMass::AimRange;

		auto Trace = Trace::InitChannel(ETraceTypeQuery::PlayerAiming);
		auto HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);

		if (HitResult.bBlockingHit && HitResult.Component != nullptr)
		{
			return FDarkMassSurfaceData(HitResult.Component,
				HitResult.BoneName,
				HitResult.ImpactPoint,
				HitResult.ImpactNormal);
		}

		return FDarkMassSurfaceData(nullptr,
			NAME_None,
			HitResult.TraceEnd,
			(TraceStart - TraceEnd).GetSafeNormal());
	}
}