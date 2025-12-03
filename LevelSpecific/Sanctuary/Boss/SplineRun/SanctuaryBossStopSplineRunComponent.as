class USanctuaryBossStopSplineRunComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float StopAtDistance = 43000;

	bool bShouldStop = true;

	access StopperCapa = private, USanctuaryBossStopSplineRunCapability;
	access : StopperCapa ASanctuaryBossSplineRun SplineRunParent = nullptr;
	access : StopperCapa AActor SplineRunChildActor = nullptr;

	void AssignSplineRun(ASanctuaryBossSplineRun SplineRun, AActor AttachedSplineRunChild)
	{
		SplineRunParent = SplineRun;
		SplineRunChildActor = AttachedSplineRunChild;
	}
};