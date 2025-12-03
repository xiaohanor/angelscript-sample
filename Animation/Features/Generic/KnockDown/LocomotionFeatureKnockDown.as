struct FLocomotionFeatureKnockDownAnimData
{
	UPROPERTY(Category = "Grounded|Start")
	FHazePlaySequenceData StartForward;

	UPROPERTY(Category = "Grounded|Start")
	FHazePlaySequenceData StartLeft;

	UPROPERTY(Category = "Grounded|Start")
	FHazePlaySequenceData StartRight;

	UPROPERTY(Category = "Grounded|Start")
	FHazePlaySequenceData StartBack;


	UPROPERTY(Category = "Grounded|Laydown")
	FHazePlaySequenceData GroundForward;

	UPROPERTY(Category = "Grounded|Laydown")
	FHazePlaySequenceData GroundBack;


	UPROPERTY(Category = "Grounded|Exit")
	FHazePlaySequenceData ForwardStandToRun;

	UPROPERTY(Category = "Grounded|Exit")
	FHazePlaySequenceData BackStandToRun;
	
	UPROPERTY(Category = "Grounded|Exit")
	FHazePlaySequenceData StandForward;

	UPROPERTY(Category = "Grounded|Exit")
	FHazePlaySequenceData StandBack;


	UPROPERTY(Category = "Air|Mh")
	FHazePlaySequenceData InAirMhFwd;

	UPROPERTY(Category = "Air|Mh")
	FHazePlaySequenceData InAirMhBck;

	UPROPERTY(Category = "Air|Exit")
	FHazePlaySequenceData InAirExitFwd;

	UPROPERTY(Category = "Air|Exit")
	FHazePlaySequenceData InAirExitBck;


	UPROPERTY(Category = "Air|Land")
	FHazePlaySequenceData ForwardFlyLand;

	UPROPERTY(Category = "Air|Land")
	FHazePlaySequenceData BackFlyLand;


	bool IsStartSequence(UAnimSequenceBase Anim)
	{
		if (Anim == StartForward.Sequence)
			return true;
		if (Anim == StartLeft.Sequence)
			return true;
		if (Anim == StartRight.Sequence)
			return true;
		if (Anim == StartBack.Sequence)
			return true;

		return false;
	}

	float GetStartDuration(EHazeCardinalDirection Direction, bool bIsInAir)
	{
		if (!bIsInAir)
		{
			if (Direction == EHazeCardinalDirection::Forward)
				return StartForward.Sequence.PlayLength;
			if (Direction == EHazeCardinalDirection::Left)
				return StartLeft.Sequence.PlayLength;
			if (Direction == EHazeCardinalDirection::Right)
				return StartRight.Sequence.PlayLength;

			return StartBack.Sequence.PlayLength;
		}
		else
		{
			return 0;
			// if (Direction == EHazeCardinalDirection::Forward)
			// 	return ForwardFly.Sequence.PlayLength;
			// if (Direction == EHazeCardinalDirection::Left)
			// 	return LeftFly.Sequence.PlayLength;
			// if (Direction == EHazeCardinalDirection::Right)
			// 	return RightFly.Sequence.PlayLength;

			// return BackFly.Sequence.PlayLength;
		}
	}
}

class ULocomotionFeatureKnockDown : UHazeLocomotionFeatureBase
{
	default Tag = n"KnockDown";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureKnockDownAnimData AnimData;

	UPROPERTY(Category = "Settings")
	bool bUsePhysics = true;
}
