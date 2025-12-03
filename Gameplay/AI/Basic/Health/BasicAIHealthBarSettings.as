enum EBasicAIHealthBarVisibility
{
	AlwaysShow,
	OnlyShowWhenHurt,
}

class UBasicAIHealthBarSettings : UHazeComposableSettings
{
	// Name of scene component health bar will be attached to (or root component by default)
	UPROPERTY(Category = "GUI")
	FName HealthBarAttachComponentName = NAME_None;

	// Socket health bar will be attached to.
	UPROPERTY(Category = "GUI")
	FName HealthBarAttachSocket = NAME_None;

	// Local offset of healthbar from attachment component/socket/root
	UPROPERTY(Category = "GUI")
	FVector HealthBarOffset = FVector(0.0, 0.0, 180.0);

	// When to show health bar
	UPROPERTY(Category = "GUI")
	EBasicAIHealthBarVisibility HealthBarVisibility = EBasicAIHealthBarVisibility::OnlyShowWhenHurt;

	UPROPERTY(Category = "GUI")
	int HealthBarSegments = 1;
}

