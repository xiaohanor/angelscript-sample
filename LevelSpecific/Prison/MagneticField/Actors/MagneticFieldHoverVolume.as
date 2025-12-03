enum EMagneticFieldHoverVolumeSide
{
	ActorRight,
	ActorForward,
}

UCLASS(NotBlueprintable)
class AMagneticFieldHoverVolume : APlayerTrigger
{
	default BrushColor = FLinearColor::LucBlue;

	UPROPERTY(EditInstanceOnly, Category = "Hover Volume|Fall Velocity")
	bool bLimitFallVelocity = true;

	UPROPERTY(EditInstanceOnly, Category = "Hover Volume|Fall Velocity", Meta = (EditCondition = "bLimitFallVelocity"))
	float FallVelocityKeptFraction = 0.2;

	UPROPERTY(EditInstanceOnly, Category = "Hover Volume|Charge Time")
	bool bSetChargeTime = true;

	UPROPERTY(EditInstanceOnly, Category = "Hover Volume|Charge Time", Meta = (EditCondition = "bSetChargeTime"))
	float ChargeTime = 0.1;

	UPROPERTY(EditInstanceOnly, Category = "Hover Volume|Dampen Side Velocity")
	bool bDampenSideVelocity = true;

	UPROPERTY(EditInstanceOnly, Category = "Hover Volume|Dampen Side Velocity", Meta = (EditCondition = "bDampenSideVelocity"))
	float DampenSideVelocityForce = 2.0;

	UPROPERTY(EditInstanceOnly, Category = "Hover Volume|Dampen Side Velocity", Meta = (EditCondition = "bDampenSideVelocity"))
	EMagneticFieldHoverVolumeSide Side = EMagneticFieldHoverVolumeSide::ActorRight;

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);

		auto PlayerComp = UMagneticFieldPlayerComponent::Get(Player);
		if(PlayerComp == nullptr)
			return;

		check(PlayerComp.CurrentHoverVolume == nullptr);

		PlayerComp.CurrentHoverVolume = this;
	}

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);

		
		auto PlayerComp = UMagneticFieldPlayerComponent::Get(Player);
		if(PlayerComp == nullptr)
			return;

		check(PlayerComp.CurrentHoverVolume == this);

		PlayerComp.CurrentHoverVolume = nullptr;
	}

	FVector GetSideVector() const
	{
		switch(Side)
		{
			case EMagneticFieldHoverVolumeSide::ActorRight:
				return ActorRightVector;

			case EMagneticFieldHoverVolumeSide::ActorForward:
				return ActorForwardVector;
		}
	}
};