/** 
 * A special case movement resolver for when the magnet drone is attracting towards a surface.
 * The regular teleport resolver does not sweep to check for collisions, and the sweeping
 * resolver can cause velocity and friction issues when we want to move this quickly and
 * stop immediately upon hitting a surface.
*/
class UMagnetDroneAttractionMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = UMagnetDroneAttractionMovementData;

	private const UMagnetDroneAttractionMovementData MovementData;
	private TArray<FMagnetDroneImpactResponseComponentAndData> Impacts;
	private bool bFinishedAttraction = false;
	private bool bLostAllVelocityAfterImpact = false;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MovementData = Cast<UMagnetDroneAttractionMovementData>(Movement);

		Impacts.Reset();
		bFinishedAttraction = false;
		bLostAllVelocityAfterImpact = false;
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		if(HitImpactResponseComponent(Hit))
			return EMovementResolverHandleMovementImpactResult::Skip;

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	// We are considered airborne until we hit something
	protected bool IsLeavingGround() const override
	{
		return true;
	}

	bool ShouldProjectMovementOnImpact(FMovementHitResult Impact) const override
	{
		const FVector Velocity = IterationState.GetDelta().Velocity;

		// Only stop if the swept surface is too steep to simply slide past
		const float SurfaceAngle = Velocity.GetSafeNormal().GetAngleDegreesTo(Impact.GetNormal());
		const float SlideAngle = MagnetDrone::SlideAngleThreshold;
		if(SurfaceAngle < SlideAngle)
			return false;

		// If we hit the wrong target we must not project our movement
		// But also, if we did hit the correct target and should attach, we should not project since we want to just stop
		FMagnetDroneTargetData PendingTargetData = MovementData.TargetData;
		EMagnetDroneIntendedTargetResult Result = MagnetDrone::WasImpactIntendedTarget(
			Impact.ConvertToHitResult(),
			IterationState.CurrentLocation,
			Velocity,
			PendingTargetData
		);

		if(Result == EMagnetDroneIntendedTargetResult::Finish)
			return false;
		
		return Super::ShouldProjectMovementOnImpact(Impact);
	}

	void ApplyImpactOnDeltas(FMovementHitResult Impact) override
	{
		const FVector VelocityBeforeImpact = IterationState.GetDelta().Velocity;

		Super::ApplyImpactOnDeltas(Impact);

		const FVector VelocityAfterImpact = IterationState.GetDelta().Velocity;

		if(!VelocityBeforeImpact.IsNearlyZero() && VelocityAfterImpact.IsNearlyZero(1))
		{
			// If we were moving before the impact, but aren't anymore, we must flag that we might be stuck
			// This could also mean that we finished the attraction, but we can't really know that, so
			// we let the capability decide.
			bLostAllVelocityAfterImpact = true;
		}
	}

	private bool HitImpactResponseComponent(const FMovementHitResult& MovementHit)
	{
		if(!MovementHit.IsValidBlockingHit())
			return false;

		auto ResponseComp = UMagnetDroneImpactResponseComponent::Get(MovementHit.Actor);
		if(ResponseComp == nullptr)
			return false;

		FMagnetDroneImpactResponseComponentAndData ResponseCompAndData;
		ResponseCompAndData.ResponseComp = ResponseComp;

		FMagnetDroneOnImpactData ImpactData;
		const FHitResult HitResult = MovementHit.ConvertToHitResult();
		ImpactData.Component = HitResult.Component;
		ImpactData.ImpactPoint = HitResult.ImpactPoint;
		ImpactData.ImpactNormal = HitResult.ImpactNormal;

		ImpactData.Velocity = IterationState.DeltaToTrace / IterationTime;
		ResponseCompAndData.ImpactData = ImpactData;

		Impacts.Add(ResponseCompAndData);

		if(ResponseComp.bIgnoreAfterImpact)
		{
			IterationTraceSettings.AddPermanentIgnoredActor(ResponseComp.Owner);
			return true;
		}

		return false;
	}

	bool ShouldAlignWorldUpWithContact(FMovementHitResult Contact) const override
	{
		if(MagnetDrone::IsImpactMagnetic(Contact, false))
		{
			// Always align with magnetic surfaces during attraction
			return true;
		}

		return Super::ShouldAlignWorldUpWithContact(Contact);
	}

	void ResolveAndApplyMovementRequest(UHazeMovementComponent MovementComponent) override
	{
		Super::ResolveAndApplyMovementRequest(MovementComponent);

		if(bLostAllVelocityAfterImpact)
		{
			auto AttractionComp = UMagnetDroneAttractionComponent::Get(MovementComponent.Owner);
			AttractionComp.AttractionMightBeStuckFrame = Time::FrameNumber;
		}

		for(auto ResponseCompAndData : Impacts)
		{
			ResponseCompAndData.ResponseComp.OnImpact.Broadcast(ResponseCompAndData.ImpactData);
		}
	}
}