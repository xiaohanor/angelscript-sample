UCLASS(Abstract)
class UPooledWidget : UHazeUserWidget
{
	// Whether the same widget can be reused for the same instigator, even if it is still animating away
	UPROPERTY(Category = "Pooled Widget")
	bool bReuseDuringRemoveForSameInstigator = false;

	void OnTakenFromPool() {}
	void OnReturnedToPool() {}

	// Pooled widget state
	bool bIsInPool = false;
	FInstigator PooledInstigator;
	uint PoolFrameUsage = 0;
};