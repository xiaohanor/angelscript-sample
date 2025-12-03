class USummitAIGentlemanSettings : UHazeComposableSettings
{
	 
};

namespace SummitGentlemanToken
{
	UFUNCTION()
	float GetRangedScore(AHazeActor Target, AHazeActor InOwner)
	{
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(Target);
		FVector DirFromInstigator = (InOwner.ActorCenterLocation - Target.ActorCenterLocation).GetSafeNormal();

		if (PlayerTarget != nullptr)
		{
			return DirFromInstigator.DotProduct(PlayerTarget.ViewRotation.Vector());
		}
		
		//TODO if targeting non player targets, add logic
		return 1.0;
	}
	
	UFUNCTION()
	float GetMeleeScore(AHazeActor Target, AHazeActor InOwner, float DistanceWeight = 1.0 / 2500.0)
	{
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(Target);
		FVector TargetOffset = InOwner.ActorCenterLocation - Target.ActorCenterLocation;
		FVector DirFromInstigator = TargetOffset.GetSafeNormal();
		float Distance = TargetOffset.Size();
		//Weight divider - higher the weight, smaller the number
		Distance *= DistanceWeight;
		float DistanceScore = 1.0 - Distance;

		if (PlayerTarget != nullptr)
		{
			return DirFromInstigator.DotProduct(PlayerTarget.ViewRotation.Vector()) + DistanceScore;
		}
		
		//TODO if targeting non player targets, add logic
		return 1.0;
	}
}