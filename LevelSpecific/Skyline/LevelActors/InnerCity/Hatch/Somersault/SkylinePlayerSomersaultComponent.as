event void FOnBackwardsSomersaultComplete();

UCLASS(Abstract)
class USkylineInnerPlayerBackwardsSomersaultComponent : UActorComponent
{
	FHazeStructQueue ActionQueue;
	FOnBackwardsSomersaultComplete OnBackwardsSomersaultComplete;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence Animation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	FSkylineInnerPlayerBackwardsSomersaultData Data;

	void AddSomersault(FSkylineInnerPlayerBackwardsSomersaultData SomersaultData)
	{
		Data = SomersaultData;
		
		ActionQueue.Reset();

		FSkylineInnerPlayerBackwardsSomersaultJumpActionActivateParams Jump;
		Jump.TimeDilation = SomersaultData.TimeDilation;
		Jump.Impulse = SomersaultData.Impulse;
		Jump.Duration = SomersaultData.JumpDuration;
		Jump.StartGravityDirection = SomersaultData.StartGravityDirection;
		Jump.TargetGravityDirection = SomersaultData.TargetGravityDirection;
		ActionQueue.Queue(Jump);

		FSkylineInnerPlayerBackwardsSomersaultSlowAimActionData SlowAim;
		SlowAim.TimeDilation = SomersaultData.TimeDilation;
		SlowAim.GravityScale = SomersaultData.GravityScale;
		SlowAim.Duration = SomersaultData.SlowAimDuration;
		ActionQueue.Queue(SlowAim);

		FSkylineInnerPlayerBackwardsSomersaultDropActionData Drop;
		Drop.TimeDilation = SomersaultData.TimeDilation;
		Drop.GravityScale = SomersaultData.GravityScale;
		Drop.Duration = SomersaultData.DropDuration;
		ActionQueue.Queue(Drop);
	}
}