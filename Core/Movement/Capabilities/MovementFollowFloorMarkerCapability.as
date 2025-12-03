
class UMovementFollowFloorMarkerCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementFollow);

	UHazeMovementComponent MoveComp;
	UPlayerHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		HealthComp = UPlayerHealthComponent::Get(Owner);

		if(HealthComp != nullptr)
		{
			HealthComp.OnDeathTriggered.AddUFunction(this, n"OnDeathStateChange");
			HealthComp.OnFinishDying.AddUFunction(this, n"OnDeathStateChange");
			HealthComp.OnReviveTriggered.AddUFunction(this, n"OnDeathStateChange");
		}

		MoveComp.ApplyFollowEnabledOverride(
			this,
			EMovementFollowEnabledStatus::FollowEnabled,
			EInstigatePriority::Low
		);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		MoveComp.ClearFollowEnabledOverride(this);
	}

	UFUNCTION()
	private void OnDeathStateChange()
	{
		UpdateFollowState();
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		UpdateFollowState();
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		UpdateFollowState();
	}

	void UpdateFollowState()
	{
		if (IsBlocked())
		{
			if (HealthComp != nullptr && HealthComp.bIsDead)
			{
				MoveComp.ApplyFollowEnabledOverride(
					this,
					EMovementFollowEnabledStatus::OnlyFollowReferenceFrame,
					EInstigatePriority::Low
				);
			}
			else
			{
				MoveComp.ApplyFollowEnabledOverride(
					this,
					EMovementFollowEnabledStatus::FollowDisabled,
					EInstigatePriority::Low
				);
			}
		}
		else
		{
			MoveComp.ApplyFollowEnabledOverride(
				this,
				EMovementFollowEnabledStatus::FollowEnabled,
				EInstigatePriority::Low
			);
		}
	}
}