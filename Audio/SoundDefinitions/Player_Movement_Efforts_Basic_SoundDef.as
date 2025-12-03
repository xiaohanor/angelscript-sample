UCLASS(Abstract)
class UPlayer_Movement_Efforts_Basic_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	TArray<FEffortEventDataGroup> TagDatas;

	private FEffortEventData LastData;

	UFUNCTION(BlueprintEvent, DisplayName = "Trigger Effort")
	void OnEffort(UHazeVoxAsset DefaultVox, UHazeVoxAsset OpenMouthVox, UHazeVoxAsset ClosedMouthVox, const FName Tag)  {};

	UFUNCTION(BlueprintEvent, DisplayName = "Trigger Special Effort")
	void OnSpecialEffort(const FName Tag)  {};

	UHazeMovementAudioComponent MoveAudioComp;
	UPlayerEffortAudioComponent EffortComp;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MovementAudio::Player::CanPerformEfforts(MoveAudioComp))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MovementAudio::Player::CanPerformEfforts(MoveAudioComp))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MoveAudioComp = UHazeMovementAudioComponent::Get(PlayerOwner);
		EffortComp = UPlayerEffortAudioComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveAudioComp.OnMovementTagChanged.AddUFunction(this, n"OnMovementChanged");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveAudioComp.OnMovementTagChanged.UnbindObject(this);
	}
 
	UFUNCTION()
	void OnMovementChanged(FName Group, FName Tag, bool bIsEnter, bool bIsOverride)
	{
		if(bIsEnter)
		{
			FEffortEventData EventData;
			if(GetEffortEventData(Group, Tag, EventData))
			{
				// Call Effort-trigger in BP
				OnEffort(EventData.VoxAsset, EventData.OpenMouthVoxAsset, EventData.ClosedMouthVoxAsset, EventData.Tag);
				LastData = EventData;
			}
			else if(Group == n"Player_Efforts" && (Tag == n"Land" || Tag == n"Jump"))
			{
				OnSpecialEffort(Tag);
			}
		}
	}

	UFUNCTION(BlueprintPure)
	UHazeVoxAsset GetVoxAssetForActiveTag(const FName Group)
	{
		const FName CurrentGroupTag = MoveAudioComp.GetActiveMovementTag(Group);

		FEffortEventData EventData;
		if(GetTagData(Group, CurrentGroupTag, EventData))
		{
			return EventData.VoxAsset;
		}

		return nullptr;		
	}

	private bool GetTagData(const FName Group, const FName Tag, FEffortEventData& outData)
	{
		for(auto& TagData : TagDatas)
		{
			if(TagData.Group == Group)
			{
				for(auto EventData : TagData.EventDatas)
				{
					if(EventData.Tag == Tag)
					{
						outData = EventData;
						return true;
					}
				}
			}
		}

		return false;
	}

	bool GetEffortEventData(const FName InGroup, const FName InTag, FEffortEventData& OutData)
	{
		if(InGroup == LastData.Group && InTag == LastData.Tag)
		{
			OutData = LastData;
			return true;
		}

		for(auto& DataGroup : TagDatas)
		{
			if(DataGroup.Group != InGroup)
				continue;

			for(auto& EventData : DataGroup.EventDatas)
			{
				if(EventData.Tag == InTag)
				{
					OutData = EventData;
					return true;
				}
			}
		}

		return false;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Exertion"))
	float GetExertion()
	{
		return EffortComp.GetExertion();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is In Open Mouth Breathing Cycle"))
	bool IsInOpenMouthBreathingCycle()
	{
		return EffortComp.bIsInOpenMouthBreathingCycle;
	}

	UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe)) // Used for StandardActionInhibitor
	bool IsIntValueBetween(int Value, int Min, int Max)
	{
		return Value >= Min && Value <= Max;
	}

}
