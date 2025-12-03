UCLASS(NotBlueprintable)
class AMagneticFieldRadiusVolume : APlayerTrigger
{
	default BrushColor = FLinearColor::LucBlue;

	UPROPERTY(EditAnywhere)
	float InnerRadius = 600.0;

	UPROPERTY(EditAnywhere)
	float OuterRadius = 200.0;

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);

		UMagneticFieldPlayerComponent PlayerComp = UMagneticFieldPlayerComponent::Get(Player);
		if (PlayerComp == nullptr)
			return;

		PlayerComp.UpdateRadius(InnerRadius, OuterRadius);
	}

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);
		
		UMagneticFieldPlayerComponent PlayerComp = UMagneticFieldPlayerComponent::Get(Player);
		if (PlayerComp == nullptr)
			return;

		PlayerComp.ResetRadius();
	}
};