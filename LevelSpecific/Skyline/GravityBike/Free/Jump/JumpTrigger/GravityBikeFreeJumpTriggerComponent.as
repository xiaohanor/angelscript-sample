UCLASS(NotBlueprintable)
class UGravityBikeFreeJumpTriggerComponent : UHazeMovablePlayerTriggerComponent
{
	UPROPERTY(EditAnywhere, Category = "Jump Trigger")
	bool bActivateOnlyIfGrounded = true;

	UPROPERTY(EditAnywhere, Category = "Jump Trigger")
	bool bDeactivateOnlyIfGrounded = true;

	UPROPERTY(EditAnywhere, Category = "Jump Trigger|Boost")
	bool bApplyBoost = true;

	UPROPERTY(EditAnywhere, Category = "Jump Trigger|Boost", Meta = (EditCondition = "bApplyBoost"))
	float BoostScale = 1.0;

	UPROPERTY(EditAnywhere, Category = "Jump Trigger|Jump")
	bool bBlockJump = true;

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		auto GravityBike = GravityBikeFree::GetGravityBike(Player);
		if(GravityBike == nullptr)
			return;

		auto JumpComp = UGravityBikeFreeJumpComponent::Get(GravityBike);
		if(JumpComp == nullptr)
			return;

		JumpComp.JumpTriggers.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		auto GravityBike = GravityBikeFree::GetGravityBike(Player);
		if(GravityBike == nullptr)
			return;

		auto JumpComp = UGravityBikeFreeJumpComponent::Get(GravityBike);
		if(JumpComp == nullptr)
			return;

		JumpComp.JumpTriggers.RemoveSingleSwap(this);
	}

	bool ShouldApplyBoost(const AGravityBikeFree GravityBike) const
	{
		if(!bApplyBoost)
			return false;

		if(bActivateOnlyIfGrounded && GravityBike.IsAirborne.Get())
			return false;

		return true;
	}

	bool ShouldBlockJump(const AGravityBikeFree GravityBike) const
	{
		if(!bBlockJump)
			return false;

		if(bActivateOnlyIfGrounded && GravityBike.IsAirborne.Get())
			return false;

		return true;
	}
};