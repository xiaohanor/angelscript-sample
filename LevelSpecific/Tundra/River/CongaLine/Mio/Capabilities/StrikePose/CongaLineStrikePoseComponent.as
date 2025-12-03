event void FOnCongaLineStrikePose();

enum ECongaLineStrikePose
{
	None = 0,

	Up = 1,
	Left = 2,
	Right = 3,
	Down = 4,
};


UCLASS(Abstract)
class UCongaLineStrikePoseComponent : UActorComponent
{

	UPROPERTY()
	FOnCongaLineStrikePose OnStrikePose;


	AHazePlayerCharacter Player;
	bool bActive = true;
	ECongaLineStrikePose CurrentPose = ECongaLineStrikePose::Down;
	int RandomPoseAnimVariation;
	uint SuccessfullyHitInputFrame = 0;
	bool bIsPosing = false;
	float LastPoseTime = 0;
	
	// UPROPERTY()
	// UForceFeedbackEffect ForceFeedback;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		auto CongaLineComp = UCongaLinePlayerComponent::Get(Player);

		ACongaLineManager Manager = CongaLine::GetManager();
		//Manager.OnBeatEvent.AddUFunction(this, n"OnBeat");
		Manager.OnMeasureEvent.AddUFunction(this, n"OnMeasure");

	}

	bool CanPose() const
	{
		return Time::GameTimeSeconds - LastPoseTime >= CongaLine::StrikePoseCooldown;
	}

	// UFUNCTION()
	// private void OnBeat(FCongaLineOnBeatEventData EventData)
	// {
	// 	if(EventData.Beat != CongaLine::BeatsPerMeasure)
	// 	{
	// 		Player.PlayForceFeedback(ForceFeedback, false, false, this, 1);
	// 	}
	// }

	UFUNCTION()
	private void OnMeasure(FCongaLineOnMeasureEventData EventData)
	{
		GenerateNewPoseToStrike();
		SuccessfullyHitInputFrame = Time::FrameNumber+1;
	}

	void StrikeNewPose()
	{
		GenerateNewPoseToStrike();
		LastPoseTime = Time::GameTimeSeconds;
		SuccessfullyHitInputFrame = Time::FrameNumber+1;
	}

	private void GenerateNewPoseToStrike()
	{
		ECongaLineStrikePose PreviousPose = CurrentPose;

		CurrentPose = GetRandomPose();

		RandomPoseAnimVariation = Math::RandRange(0, 1);

		// Make sure we don't play the same pose twice in a row
		while(CurrentPose == PreviousPose)
		{
			CurrentPose = GetRandomPose();
		}
	}


	ECongaLineStrikePose GetRandomPose() const
	{
		return ECongaLineStrikePose(Math::RandRange(1, 4));
	}


	bool ShouldStrikePose() const
	{
		return SuccessfullyHitInputFrame == Time::FrameNumber;
	}
	
	bool IsStrikingPose() const
	{
		return bIsPosing;
	}
};