class UDarkParasiteUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	FDarkParasiteTargetData FocusedData;
	FDarkParasiteTargetData AttachedData;
	FDarkParasiteTargetData GrabbedData;

	uint LastAttachFrame;
	uint LastGrabFrame;

	private AHazePlayerCharacter Player;
	private UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	FDarkParasiteTargetData GetAimTargetData()
	{
		auto AimResult = GetAimingTarget();

		const FVector TraceStart = Math::ClosestPointOnInfiniteLine(
			AimResult.AimOrigin,
			AimResult.AimOrigin + (AimResult.AimDirection * DarkParasite::AimRange),
			Player.ActorCenterLocation
		);
		const FVector TraceEnd = TraceStart + AimResult.AimDirection * DarkParasite::AimRange;

		auto Trace = Trace::InitChannel(ETraceTypeQuery::PlayerAiming);
		auto HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);

		if (HitResult.bBlockingHit && HitResult.Component != nullptr)
		{
			// Prioritize the auto aim target component
			if (AimResult.AutoAimTarget != nullptr &&
				AimResult.AutoAimTarget.Owner == HitResult.Actor)
			{
				return FDarkParasiteTargetData(AimResult.AutoAimTarget,
					HitResult.ImpactPoint);
			}

			// Try to get the closest target component
			TArray<UTargetableComponent> TargetComponents;
			DarkParasite::GetHierarchyTargetComponents(TargetComponents,
				AimTargetableClass,
				HitResult.Actor);

			auto ClosestComponent = GetClosestTargetComponent(TargetComponents, HitResult.ImpactPoint);
			if (ClosestComponent != nullptr)
			{
				return FDarkParasiteTargetData(ClosestComponent,
					HitResult.ImpactPoint);
			}

			// If the target doesn't have any target components, we can't attach
			//  but we can still grab it, so it's still a valid target
			return FDarkParasiteTargetData(HitResult.Component,
				HitResult.ImpactPoint);
		}

		return FDarkParasiteTargetData();
	}

	UTargetableComponent GetClosestTargetComponent(
		const TArray<UTargetableComponent>&in TargetComponents,
		const FVector& WorldLocation)
	{
		float ClosestDistanceSqr = MAX_flt;
		UTargetableComponent ClosestComponent = nullptr;
		for (auto TargetComponent : TargetComponents)
		{
			if (TargetComponent.IsDisabledForPlayer(Player))
				continue;

			const float DistanceSqr = TargetComponent.WorldLocation.DistSquared(WorldLocation);
			if (DistanceSqr < ClosestDistanceSqr)
			{
				ClosestDistanceSqr = DistanceSqr;
				ClosestComponent = TargetComponent;
			}
		}

		return ClosestComponent;
	}

	bool HasLineOfSight(const USceneComponent TargetComponent) const
	{
		if (!AttachedData.IsValid() || TargetComponent == nullptr)
			return false;

		const FVector TraceStart = AttachedData.TargetComponent.WorldLocation;
		const FVector TraceEnd = TargetComponent.WorldLocation;

		auto Trace = Trace::InitChannel(ETraceTypeQuery::WorldGeometry);
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);
		auto HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);

		return (!HitResult.bBlockingHit);
	}
	
	bool IsAiming() const
	{
		if (AimComp.IsAiming(this))
			return true;

		return false;
	}

	FVector GetAimOrigin() const property
	{
		if (AimComp.IsAiming(this))
			return Player.ViewLocation;

		devError("We're not aiming with any aiming component.");
		return FVector::ZeroVector;
	}

	FVector GetAimDirection() const property
	{
		if (AimComp.IsAiming(this))
			return Player.ViewRotation.Vector();

		devError("We're not aiming with any aiming component.");
		return FVector::ForwardVector;
	}

	UClass GetAimTargetableClass() const property
	{
		if (AimComp.IsAiming(this))
			return UDarkParasiteTargetComponent;

		devError("We're not aiming with any aiming component.");
		return nullptr;
	}

	FAimingResult GetAimingTarget() const
	{
		if (AimComp.IsAiming(this))
			return AimComp.GetAimingTarget(this);

		devError("We're not aiming with any aiming component.");
		return FAimingResult();
	}
}