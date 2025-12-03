event void FOnLavaFlowReachedEnd(AForgeLavaBall ForgeLavaBall);

class UForgeLavaFlowComponent : UActorComponent 
{
	UPROPERTY(EditAnywhere)
	bool bFinalPath = false;

	UPROPERTY()
	FOnLavaFlowReachedEnd OnLavaFlowReachedEnd;
}