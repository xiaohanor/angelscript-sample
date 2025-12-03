class UTundraGnatComponent : UActorComponent
{
	AHazeActor HazeOwner;

	AActor Host;

	// Zoe does not have this component when gnats spawn for some reason.
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;

	bool bHasCompletedEntry = false;

	FHazeRuntimeSpline ClimbSpline;
	float ClimbDistAlongSpline = 0.0;
	FName ClimbBone = NAME_None;
	UTundraGnatEntryScenepointComponent ClimbScenepoint = nullptr;
	bool bHasStartedClimbing = false;
	
	FVector ClimbLoc;

	AActor LeapEntryTarget = nullptr;
	float LeapAlpha = 0.0;

	AActor PassengerOnBeaverSpear = nullptr;

	bool bLatchedOn = false;
	bool bAboutToBeKnockedOff = false;
	bool bShakenOff = false; // Shaken off by Zoe button mash (not currently allowed)
	bool bThrownByMonkey = false;
	AHazeActor ThrownAtTarget = nullptr;
	bool bTargetedByMonkeyThrow = false;
	bool bGoBallistic = false;

	bool bFallFromTower = false;

	bool bFleeingLeap = false;
	FVector FleeingLeapImpulse;

	UTundraGnatSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		Settings = UTundraGnatSettings::GetSettings(HazeOwner);
	}

	void KnockOff(FVector Impulse)
	{
		HazeOwner.AddMovementImpulse(Impulse);
		bGoBallistic = true;
		bAboutToBeKnockedOff = false;
	}

	bool IsAtEndOfSpline(float Threshold) const
	{
		if (ClimbSpline.Points.Num() == 0)
			return true;
		if (ClimbDistAlongSpline > ClimbSpline.Length - Threshold)
			return true;
		return false;
	}

	UStaticMeshComponent GetHostBody() const property
	{
		if (Host == nullptr)
			return nullptr;
		return UStaticMeshComponent::Get(Host, n"Body");
	}

	FVector GetAvoidLocationOnHost(FVector LocationToAvoid, float AvoidRange)
	{
		// Back away from threat when close, but don't move too far from walking stick center
		FVector OwnLoc = Owner.ActorLocation;
		FVector AwayDir = (OwnLoc - LocationToAvoid).GetSafeNormal2D();
		FVector AwayLoc = OwnLoc + AwayDir * AvoidRange;
		USceneComponent Body = HostBody;
		if (Body == nullptr)
			return AwayLoc;

		FVector HostFront = Body.WorldLocation + Body.ForwardVector * 2600.0;
		FVector HostRear = Body.WorldLocation + Body.ForwardVector * 200.0;
		FVector CenterLoc; float Dummy;
		Math::ProjectPositionOnLineSegment(HostFront, HostRear, AwayLoc, CenterLoc, Dummy);
		const float BodyRadius = 1600.0;
		if (AwayLoc.IsWithinDist2D(CenterLoc, BodyRadius))
			return AwayLoc; // Within walking stick walkable area

		// Outside of safe area, move to the side along edge of area
		FVector EdgeLoc = CenterLoc + (AwayLoc - CenterLoc).GetSafeNormal2D() * BodyRadius;
		FVector SideDir = AwayDir.CrossProduct(FVector::UpVector);
		if (SideDir.DotProduct(CenterLoc - OwnLoc) < 0.0)
			SideDir *= -1.0;
		FVector SideLoc = EdgeLoc + SideDir * AvoidRange;
		FVector AdjustedCenterLoc;
		Math::ProjectPositionOnLineSegment(HostFront, HostRear, SideLoc, AdjustedCenterLoc, Dummy);
		AwayLoc = AdjustedCenterLoc + (SideLoc - AdjustedCenterLoc).GetSafeNormal2D() * BodyRadius;
		return AwayLoc;
	}

	void CheckGnapeImpacts(UPlayerSnowMonkeyThrowGnapeComponent ThrowerComp, UTundraGnapeAnnoyedPlayerComponent AnnoyedByGnatsComp)
	{
		if (HasControl())
		{
			AHazeActor OtherGnape = GetStruckGnape(ThrowerComp);
			if (OtherGnape != nullptr)
			{
				// If we hit a gnape currently annoying tree guardian, we start a chain reaction hitting all other annoying gnapes as well
				if (UTundraGnatComponent::Get(OtherGnape).bLatchedOn)
					AnnoyedByGnatsComp.KnockOffAnnoyingGnapes(HazeOwner, OtherGnape, Settings.GnapeHitGnapeRedirection, Settings.GnapeHitGnapeHeightImpulse);
				else	
					CrumbStrikeOtherGnape(OtherGnape, Gnape::GetImpactImpulse(Owner.ActorVelocity, Settings.GnapeHitGnapeRedirection, Settings.GnapeHitGnapeHeightImpulse)); 
			}
		}
	}

	AHazeActor GetStruckGnape(UPlayerSnowMonkeyThrowGnapeComponent ThrowerComp)
	{
		FVector OwnLoc = Owner.ActorLocation;
		for (AHazeActor Other : ThrowerComp.Gnapes)
		{
			if (Other == Owner)
				continue;
			if (!Other.ActorLocation.IsWithinDist2D(OwnLoc, Settings.GnapeHitGnapeRadius))
				continue;
			if (Math::Abs(Other.ActorLocation.Z - OwnLoc.Z) > Settings.GnapeHitGnapeRadius * 2.0)
				continue;
			UTundraGnatComponent OtherGnapeComp = UTundraGnatComponent::Get(Other);
			if (OtherGnapeComp.bGoBallistic)
				continue;
			if (OtherGnapeComp.bThrownByMonkey)
				continue;
			if (OtherGnapeComp.bAboutToBeKnockedOff)
				continue;
			UBasicAIHealthComponent OtherHealthComp = UBasicAIHealthComponent::Get(Other);
			if (OtherHealthComp.IsDead())
				continue;

			// Do not hit gnapes moving locally, i.e. climbing up legs as it'll look bad
			// We do handle this regardless since you could conceivably hit a gnape which 
			// has started crumb move on control side but is still moving locally on remote.
			UHazeMovementComponent OtherMoveComp = UHazeMovementComponent::Get(Other);
			if (OtherMoveComp.bResolveMovementLocally.Get())
				continue; 

			return Other;
		}
		return nullptr;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStrikeOtherGnape(AHazeActor Other, FVector Impulse)
	{
		UTundraGnatComponent::Get(Other).KnockOff(Impulse);
		HazeOwner.ActorVelocity *= 0.9;
	}
}

namespace DevTogglesGnape
{
	const FHazeDevToggleBool ZoeIgnoreGnapes;
	const FHazeDevToggleBool ShowAnimTag;
}
