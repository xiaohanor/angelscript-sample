class UAnimNotify_BattlefieldHoverboard_Trick_CameraShake : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "HoverboardCameraShake";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		auto Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
		if(Player == nullptr)
			return true; 

		if (!Player.IsCapabilityTagBlocked(BattlefieldHoverboardCapabilityTags::HoverboardTrickCameraSettings))
		{
			auto TrickSettings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
			Player.PlayCameraShake(TrickSettings.TrickStartCameraShake, this);
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
		if(Player == nullptr)
			return true; 
			
		Player.StopCameraShakeByInstigator(this);

		return true;
	}
};

class UAnimNotify_BattlefieldHoverboard_Trick_CameraSetting : UAnimNotifyState
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	float BlendInTime = 0.4;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BlendOutTime = 0.7;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "HoverboardCameraSettings";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		auto Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
		if(Player == nullptr)
			return true; 

		if (!Player.IsCapabilityTagBlocked(BattlefieldHoverboardCapabilityTags::HoverboardTrickCameraSettings))
		{
			auto TrickSettings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
			Player.ApplyCameraSettings(TrickSettings.TrickCameraSettings, BlendInTime, this, EHazeCameraPriority::High);
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
		if(Player == nullptr)
			return true; 

		Player.ClearCameraSettingsByInstigator(this, BlendOutTime);

		return true;
	}
};

class UAnimNotify_BattlefieldHoverboard_Trick_Land : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "HoverboardTrickLand";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		return true;
	}
};

class UAnimNotify_BattlefieldHoverboard_Trick_Finished : UAnimNotifyState
{

#if EDITOR
	default NotifyColor = FColor::Green;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "HoverboardTrickFinished";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		auto Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
		if(Player == nullptr)
			return true; 

		auto TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);
		if (!Player.IsCapabilityTagBlocked(BattlefieldHoverboardCapabilityTags::HoverboardTrickBoost))
		{
			if(!TrickComp.bHasPerformedTrickSinceLanding)
				TrickComp.StoreTrickBoost();
		}
			
		// TrickComp.bTrickWasCompleted = true;

		return true;
	}
};


class UAnimNotify_BattlefieldHoverboard_Trick_Fail : UAnimNotifyState
{
	
#if EDITOR
	default NotifyColor = FColor::Red;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "HoverboardTrickFail";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration,
					 FAnimNotifyEventReference EventReference) const
	{
		auto Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
		if(Player == nullptr)
			return true; 

		Player.SetAnimBoolParam(n"HoverboardFail", true);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		auto Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
		if(Player == nullptr)
			return true; 

		Player.SetAnimBoolParam(n"HoverboardFail", false);

		return true;
	}
}