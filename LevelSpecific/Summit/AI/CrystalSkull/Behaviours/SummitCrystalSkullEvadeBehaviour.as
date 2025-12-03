class USummitCrystalSkullEvadeBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCrystalSkullComponent FlyerComp;
	USummitCrystalSkullSettings FlyerSettings;
	USummitCrystalSkullArmourComponent ArmourComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FlyerComp = USummitCrystalSkullComponent::GetOrCreate(Owner);
		FlyerSettings = USummitCrystalSkullSettings::GetSettings(Owner);
		ArmourComp = USummitCrystalSkullArmourComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if ((ArmourComp != nullptr) && ArmourComp.HadArmour(2.0))
			return false;

		AHazeActor Target = TargetComp.Target;
		if (!TargetComp.IsValidTarget(Target))
			return false;

		FVector OwnLoc = Owner.ActorCenterLocation;
		FVector TargetLoc = Target.ActorCenterLocation;
		if (!TargetLoc.IsWithinDist(OwnLoc, FlyerSettings.EvadeRange))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		FVector OwnLoc = Owner.ActorCenterLocation;
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;
		if (!TargetLoc.IsWithinDist(OwnLoc, FlyerSettings.EvadeRange * 1.2))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		FlyerComp.LastEvadeTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorCenterLocation;
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;
		FVector Away = (OwnLoc - TargetLoc);
		FVector TargetDir = TargetComp.Target.ActorForwardVector;

		// Keep it mostly horizontal, so it'll be easy to track us
		Away.Z *= 0.1; 
		float AwayDist = Math::Max(1.0, Away.Size());

		FVector Evade;
		float MoveSpeed = FlyerSettings.EvadeMoveSpeed;
		if (Away.DotProduct(TargetDir) < 0.0) 
		{
			// Behind target, just move away (with speedboost when close)
			Evade = Away / AwayDist;
			MoveSpeed *= Math::GetMappedRangeValueClamped(FVector2D(FlyerSettings.EvadeNearRange * 0.25, FlyerSettings.EvadeNearRange), FVector2D(2.0, 1.0), AwayDist);
		}
		else
		{
			// In front of target. 
			if (AwayDist < FlyerSettings.EvadeNearRange)
			{
				// Move straight back at close distance, or it'll be frustrating to track us. 
				if (Owner.ActorForwardVector.DotProduct(Away) < 0.0)
					Evade = -Owner.ActorForwardVector;
				else
					Evade = Away / AwayDist;
				MoveSpeed = FlyerSettings.EvadeNearMoveSpeed;	
			}
			else
			{
				// Further out we slide to the side to encourage maneouvering
				FVector SideAwayDir = (OwnLoc - TargetLoc.PointPlaneProject(OwnLoc, TargetDir));
				SideAwayDir.Z *= 0.1; 
				SideAwayDir = SideAwayDir.GetSafeNormal(); 	
				if (SideAwayDir.DotProduct(Owner.ActorVelocity) < 0.0)
					SideAwayDir *= -1.0;
				float SideAlpha = (AwayDist - FlyerSettings.EvadeNearRange) / Math::Max(1.0, FlyerSettings.EvadeRange - FlyerSettings.EvadeNearRange);
				Evade = (Away / AwayDist).SlerpVectorTowardsAroundAxis(SideAwayDir, Owner.ActorUpVector, SideAlpha);
			}
		}
		FVector EvadeDest = Owner.ActorLocation + Evade * 10000.0;
		EvadeDest = FlyerComp.ProjectToArea(EvadeDest);
		DestinationComp.MoveTowards(EvadeDest, MoveSpeed);

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(TargetLoc + FVector(0,0,400), 100, 4, FLinearColor::Yellow, 10);
			Debug::DrawDebugLine(OwnLoc, EvadeDest, FLinearColor::Yellow, 100);
		}
#endif
	}
}
