struct FMagnetDroneAttractJumpTutorialDeactivateParams
{
	bool bFinished;
};

class UMagnetDroneAttractJumpTutorialCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMagnetDroneAttachedComponent AttachedComp;
	UMagnetDroneAttractJumpComponent AttractJumpComp;
	UMagnetDroneAttractionComponent AttractionComp;
	USceneComponent TutorialAttachComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		AttractJumpComp = UMagnetDroneAttractJumpComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);

		TutorialAttachComp = USceneComponent::GetOrCreate(Player, n"AttractJumpTutorialAttachComp");
		TutorialAttachComp.SetAbsolute(true, true, true);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttachedComp.IsAttached())
			return false;

		if(!HasShowTutorialInstigator())
			return false;

		if(!AttractJumpComp.JumpAimData.IsValidTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMagnetDroneAttractJumpTutorialDeactivateParams& Params) const
	{
		if(AttractionComp.IsAttracting())
		{
			Params.bFinished = true;
			return true;
		}

		if(!AttachedComp.IsAttached())
			return true;

		if(!HasShowTutorialInstigator())
			return true;

		if(!AttractJumpComp.JumpAimData.IsValidTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TutorialAttachComp.SetWorldLocation(GetTutorialWorldLocation());

		Player.ShowTutorialPromptWorldSpace(
			AttractJumpComp.TutorialPrompt,
			this,
			TutorialAttachComp,
			FVector::ZeroVector,
			0
		);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMagnetDroneAttractJumpTutorialDeactivateParams Params)
	{
		if(HasControl() && Params.bFinished)
		{
			CrumbFinishTutorialWithInstigators(AttractJumpComp.ShowTutorialPromptInstigators);
		}

		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TutorialAttachComp.SetWorldLocation(GetTutorialWorldLocation());
	}

	bool HasShowTutorialInstigator() const
	{
		if(AttractJumpComp.ShowTutorialPromptInstigators.IsEmpty())
			return false;

		if(AttractJumpComp.FinishedTutorialInstigators.IsEmpty())
		{
			return true;
		}
		else
		{
			for(const FInstigator& ShowInstigator : AttractJumpComp.ShowTutorialPromptInstigators)
			{
				if(!AttractJumpComp.FinishedTutorialInstigators.Contains(ShowInstigator))
					return true;
			}
		}

		return false;
	}

	FVector GetTutorialWorldLocation() const
	{
		return Math::Lerp(
			Player.ActorCenterLocation,
			AttractJumpComp.JumpAimData.GetTargetLocation(),
			0.5
		);
	}

	UFUNCTION(CrumbFunction)
	void CrumbFinishTutorialWithInstigators(TArray<FInstigator> Instigators)
	{
		for(auto Instigator : Instigators)
		{
			MagnetDrone::FinishAttractJumpTutorial(Instigator);
		}
	}
};