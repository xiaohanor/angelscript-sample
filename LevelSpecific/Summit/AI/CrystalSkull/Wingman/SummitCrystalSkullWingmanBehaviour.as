struct FSummitCrystalSkullWingmanBehaviourParams
{
	bool bRightwing;
}

class USummitCrystalSkullWingmanBehaviour : UBasicBehaviour
{
	// Movement only 
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCrystalSkullWingmanSettings WingmanSettings;
	USummitCrystalSkullsTeam SkullsTeam;
	float SideSign = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WingmanSettings = USummitCrystalSkullWingmanSettings::GetSettings(Owner);
		SkullsTeam = CrystalSkullsTeam::Join(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitCrystalSkullWingmanBehaviourParams& Params) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (SkullsTeam.Boss == nullptr)
			return false;

		// Should we activate as right or left wingman?
		if (SkullsTeam.RightWing != nullptr)
			Params.bRightwing = false;
		else if (SkullsTeam.LeftWing != nullptr)
			Params.bRightwing = true;
		else if (SkullsTeam.Boss.ActorRightVector.DotProduct(Owner.ActorLocation - SkullsTeam.Boss.ActorLocation) > 0.0)
		  	Params.bRightwing = true;
		else
		 	Params.bRightwing = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitCrystalSkullWingmanBehaviourParams Params)
	{
		Super::OnActivated();
		if (Params.bRightwing)
		{
			SideSign = 1.0; 
			SkullsTeam.RightWing = Owner;
		}
		else
		{
			SideSign = -1.0; 
			SkullsTeam.LeftWing = Owner;
		}
	}

	FVector GetBossRight() const
	{
		FVector PlayerCenter = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
		FVector BossLoc = SkullsTeam.Boss.ActorLocation;
		FVector ToBossDir = (BossLoc - PlayerCenter).GetSafeNormal2D();
		return ToBossDir.CrossProduct(FVector::UpVector);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Safety hack readded, seems this can still out of sync.
		SideSign = (SkullsTeam.RightWing == Owner) ? 1.0 : -1.0;

		FVector WingmanDest = SkullsTeam.Boss.ActorLocation + GetBossRight() * SideSign * WingmanSettings.WingmanOffset.Y;
		if (TargetComp.HasValidTarget())
			WingmanDest += (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal() * WingmanSettings.WingmanOffset.X;		
		WingmanDest.Z = SkullsTeam.Boss.ActorLocation.Z + WingmanSettings.WingmanOffset.Z;
		DestinationComp.MoveTowards(WingmanDest, WingmanSettings.WingmanSpeed);	
	}
}
