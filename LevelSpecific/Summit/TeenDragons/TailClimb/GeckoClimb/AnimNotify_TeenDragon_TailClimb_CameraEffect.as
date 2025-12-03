class UAnimNotify_TeenDragon_TailClimb_CameraEffect : UAnimNotifyState
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bLeftSide = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bFrontFoot = true;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TeenTailClimbCameraEffect";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration,
					 FAnimNotifyEventReference EventReference) const
	{
		auto Dragon = Cast<ATeenDragon>(MeshComp.Owner);
		if(Dragon == nullptr)
			return false;
		
		auto DragonComp = Dragon.DragonComponent;
		if(DragonComp == nullptr)
			return false;

		if(DragonComp.bTopDownMode)
			return false;

		auto Player = Cast<AHazePlayerCharacter>(Dragon.DragonComponent.Owner);
		if(Player == nullptr)
			return false;

		auto ClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		if(ClimbComp == nullptr)
			return false;
		
		ClimbComp.ToggleClimbCameraEffects(true, bLeftSide, bFrontFoot, this);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		auto Dragon = Cast<ATeenDragon>(MeshComp.Owner);
		if(Dragon == nullptr)
			return false;
		
		auto DragonComp = Dragon.DragonComponent;
		if(DragonComp == nullptr)
			return false;

		if(DragonComp.bTopDownMode)
			return false;

		auto Player = Cast<AHazePlayerCharacter>(Dragon.DragonComponent.Owner);
		if(Player == nullptr)
			return false;

		auto ClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		if(ClimbComp == nullptr)
			return false;
		
		ClimbComp.ToggleClimbCameraEffects(false, bLeftSide, bFrontFoot,this);

		return true;
	}
}