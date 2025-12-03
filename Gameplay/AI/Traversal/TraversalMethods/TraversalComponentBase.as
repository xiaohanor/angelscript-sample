UCLASS(Abstract)
class UTraversalComponentBase : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TArray<TSubclassOf<UTraversalMethod>> Methods;

	private ATraversalAreaActorBase Area = nullptr;

	// Property for treating Methods array as a single entry.
	TSubclassOf<UTraversalMethod> GetMethod() property
	{
		if (Methods.Num() > 0)
			return Methods[0];
		else
			return nullptr;
	}

	// Property for treating Methods array as a single entry.
	void SetMethod(TSubclassOf<UTraversalMethod> InMethod) property
	{
		if (Methods.Num() > 0)
			Methods[0] = InMethod;
		else
			Methods.AddUnique(InMethod);
	}

	void SetCurrentArea(AActor AreaActor)
	{
		Area = Cast<ATraversalAreaActorBase>(AreaActor);
	}
	ATraversalAreaActorBase GetCurrentArea() property
	{
		return Area;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnReset()
	{
		Reset();		
	}
	protected void Reset()
	{
		SetCurrentArea(nullptr);		
	}

	// Add unique traversal methods to param array.
	void AddTraversalMethods(TArray<TSubclassOf<UTraversalMethod>>& OutTraversalMethodClasses)
	{
		for(TSubclassOf<UTraversalMethod> Meth : Methods)
		{
			if (Meth.IsValid())
				OutTraversalMethodClasses.AddUnique(Meth);
		}
	}

	// Get single traversal method.
	TSubclassOf<UTraversalMethod> GetTraversalMethod()
	{
		check(Method.IsValid());
		return Method;
	}
	
	TArray<TSubclassOf<UTraversalMethod>> GetAllTraversalMethods()
	{
		for(TSubclassOf<UTraversalMethod> Meth : Methods)
		{
			check(Meth.IsValid());
		}
		return Methods;
	}
}
