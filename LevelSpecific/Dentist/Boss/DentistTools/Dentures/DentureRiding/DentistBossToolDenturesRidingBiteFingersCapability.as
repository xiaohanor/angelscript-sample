struct FDentistBossToolDenturesRidingBiteFingersActivateParams
{
	AHazePlayerCharacter Player;
	bool bIsBitingLeftHand = false;
}

struct FDentistBossToolDenturesRidingBiteFingersDeactivateParams
{
	bool bGrabberGotDestroyed = false;
}

class UDentistBossToolDenturesRidingBiteFingersCapability : UHazeCapability
{
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 60;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolDentures Dentures;

	UHazeMovementComponent MoveComp;
	UDentistBossSettings Settings;

	AHazePlayerCharacter Player;

	FVector GrabberStartLocation;
	FRotator GrabberStartRotation;

	AActor GrabberAttachActor;

	const float AttachForwardDistance = 400.0;
	const float InitialMoveDuration = 1.0;

	bool bBitLeftHand = false;
	bool bButtonMashStarted = false;

	FHazeAcceleratedFloat AccAlpha;
	FHazeAcceleratedTransform AccDenturesTransform;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().GetSingle();

		MoveComp = UHazeMovementComponent::Get(Dentures);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistBossToolDenturesRidingBiteFingersActivateParams& Params) const
	{
		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.HealthComp.IsDead())
			return false;

		if(!Dentures.ControllingPlayer.IsSet())
			return false;

		if(Dentures.bIsBitingLeftHand
		|| Dentures.bIsBitingRightHand)
		{
			Params.Player = Dentures.ControllingPlayer.Value;
			Params.bIsBitingLeftHand = Dentures.bIsBitingLeftHand;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistBossToolDenturesRidingBiteFingersDeactivateParams& Params) const
	{
		if(Dentures.bDestroyed)
		{
			Params.bGrabberGotDestroyed = false;
			return true;
		}

		if(!Dentures.ControllingPlayer.IsSet())
		{
			Params.bGrabberGotDestroyed = false;
			return true;
		}

		if(!Dentures.HealthComp.IsDead())
		{
			Params.bGrabberGotDestroyed = false;
			return true;
		}

		if(!Dentures.IsBitingHand())
		{
			Params.bGrabberGotDestroyed = false;
			return true;
		}

		if(Dentures.HandGotDestroyed())
		{
			Params.bGrabberGotDestroyed = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistBossToolDenturesRidingBiteFingersActivateParams Params)
	{
		Player = Params.Player;
		bBitLeftHand = Params.bIsBitingLeftHand;

		Dentures.bExplodeEventTriggered = false;
		bButtonMashStarted = false;
		
		if(Params.bIsBitingLeftHand)
			MoveComp.FollowComponentMovement(Dentist.SkelMesh, Dentures, EMovementFollowComponentType::ResolveCollision, EInstigatePriority::High, GetAttachBoneName());
		else
			MoveComp.FollowComponentMovement(Dentist.SkelMesh, Dentures, EMovementFollowComponentType::ResolveCollision, EInstigatePriority::High, GetAttachBoneName());

		FTransform BoneTransform = GetBoneTransform();
		FTransform DenturesRelativeTransform = Dentures.ActorTransform.GetRelativeTransform(BoneTransform);
		FVector RelativeVelocity = BoneTransform.InverseTransformVectorNoScale(Dentures.ActorVelocity);
		AccDenturesTransform.SnapTo(DenturesRelativeTransform, RelativeVelocity);

		Dentist.LookAtEnabled.Apply(false, this, EInstigatePriority::High);

		UDentistBossEffectHandler::Trigger_OnDenturesStartedBitingGrabber(Dentist);
		AccAlpha.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistBossToolDenturesRidingBiteFingersDeactivateParams Params)
	{
		MoveComp.UnFollowComponentMovement(Dentures);

		Player.StopButtonMash(this);

		Dentures.bIsBitingLeftHand = false;
		Dentures.bIsBitingRightHand = false;
		
		if(Params.bGrabberGotDestroyed
		&& !Dentures.bExplodeEventTriggered)
		{
			Dentures.ExplodeWithArm();
		}

		Dentist.LookAtEnabled.Clear(this);

		Dentist.DenturesBitingAlpha = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration >= DentistBossTimings::DenturesHandAttach)
		{
			if(!bButtonMashStarted)
			{
				StartButtonMash(Player, bBitLeftHand);
			}
			else
			{
				auto ButtonMashComp = UButtonMashComponent::Get(Player);
				float ButtonMashProgress = ButtonMashComp.GetButtonMashProgress(this);

				AccAlpha.AccelerateTo(ButtonMashProgress, 0.8, DeltaTime);
				Dentist.DenturesBitingAlpha = ButtonMashProgress;
			}
		}
		FTransform TargetRelativeTransform = GetTargetRelativeTransform();

		AccDenturesTransform.AccelerateTo(TargetRelativeTransform, 1.0, DeltaTime);
		FTransform BoneTransform = GetBoneTransform();
		FTransform NewTransform = AccDenturesTransform.Value * BoneTransform;
		Dentures.ActorLocation = NewTransform.Location;
		Dentures.ActorQuat = NewTransform.Rotation;
	}

	FVector GetStartLocation() const
	{
		return GrabberStartLocation + GrabberStartRotation.ForwardVector * AttachForwardDistance;
	}

	FVector GetTargetLocation() const
	{
		return GetStartLocation() + GrabberStartRotation.ForwardVector * Settings.DenturesDragForwardLength;
	}

	FTransform GetBoneTransform() const
	{
		return Dentist.SkelMesh.GetBoneTransform(GetAttachBoneName());
	}

	FName GetAttachBoneName() const
	{
		if(bBitLeftHand)
			return n"LeftLowerAttach";
		else
			return n"RightLowerAttach";
	}

	FTransform GetTargetTransform() const
	{
		FTransform TargetTransform;
		FTransform BoneTransform = GetBoneTransform();

		FTransform OffsetTransform = FTransform::Identity;
		TargetTransform = OffsetTransform * BoneTransform; 

		return TargetTransform;
	}

	FTransform GetTargetRelativeTransform() const
	{
		return FTransform::Identity;
	}

	void StartButtonMash(AHazePlayerCharacter InPlayer, bool bIsBitingLeftHand)
	{
		if(bButtonMashStarted)
			return;

		FButtonMashSettings ButtonMashSettings = Settings.DenturesBitingButtonMashSettings;
		if(bIsBitingLeftHand)
		{
			Dentures.BiteButtonMashWidgetRoot.AttachToComponent(Dentist.LeftHandWeakpointMesh);
			ButtonMashSettings.WidgetAttachComponent = Dentures.BiteButtonMashWidgetRoot;
			Dentist.ToggleHandWeakpointHittable(true, true);
		}
		else
		{
			Dentures.BiteButtonMashWidgetRoot.AttachToComponent(Dentist.RightHandWeakpointMesh);
			ButtonMashSettings.WidgetAttachComponent = Dentures.BiteButtonMashWidgetRoot;
			Dentist.ToggleHandWeakpointHittable(true, false);
		}	
		ButtonMashSettings.WidgetPositionOffset = FVector(150.0, 0.0, 100.0);

		InPlayer.StartButtonMash(ButtonMashSettings, this);
		InPlayer.SetButtonMashAllowCompletion(this, false);

		bButtonMashStarted = true;
	}
};