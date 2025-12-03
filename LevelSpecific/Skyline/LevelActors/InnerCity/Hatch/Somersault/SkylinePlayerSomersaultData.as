namespace SkylineInnerPlayerBackwardsSomersaultTags
{
	const FName SkylineInnerPlayerBackwardsSomersaultInstigator = n"SkylineInnerPlayerBackwardsSomersaultInstigator";
	const FName SkylineInnerPlayerBackwardsSomersault = n"SkylineInnerPlayerBackwardsSomersault";
}

struct FSkylineInnerPlayerBackwardsSomersaultData
{
	UPROPERTY(EditAnywhere, Category = "BackwardsSomersault")
	float Impulse = 1000.0;
	UPROPERTY(EditAnywhere, Category = "BackwardsSomersault")
	float TimeDilation = 0.5;
	UPROPERTY(EditAnywhere, Category = "BackwardsSomersault")
	float GravityScale = 0.1;
	UPROPERTY(EditAnywhere, Category = "BackwardsSomersault")
	float JumpDuration = 1.0;
	UPROPERTY(EditAnywhere, Category = "BackwardsSomersault")
	float SlowAimDuration = 1.0;
	UPROPERTY(EditAnywhere, Category = "BackwardsSomersault")
	float DropDuration = 0.5;
	UPROPERTY(EditAnywhere, Category = "BackwardsSomersault")
	bool bModifyCamera = true;
	FVector StartGravityDirection = FVector::UpVector;
	FVector TargetGravityDirection = FVector::UpVector;
};

asset SkylineInnerPlayerBackwardsSomersaultSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineInnerPlayerBackwardsSomersaultActionCapability);
	Capabilities.Add(USkylineInnerPlayerBackwardsSomersaultJumpActionCapability);
	Capabilities.Add(USkylineInnerPlayerBackwardsSomersaultSlowAimActionCapability);
	Capabilities.Add(USkylineInnerPlayerBackwardsSomersaultDropActionCapability);
	Capabilities.Add(USkylineInnerCityDisableInputSlideHatchPlayerCapability);
};
