class USummitNonRollKnockBackComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	bool bSpecifyComponentsForNoKnockback = false;

	UPROPERTY(EditAnywhere, Meta = (GetOptions="GetComponentNames", EditCondition = "bSpecifyComponentsForNoKnockback", EditConditionHides))
	TArray<FName> ComponentsWithNoKnockback;

	TArray<UPrimitiveComponent> FetchedComponentsWithNoKnockback;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bSpecifyComponentsForNoKnockback)
		{
			for(auto ComponentName : ComponentsWithNoKnockback)
			{
				auto Component = UPrimitiveComponent::Get(Owner, ComponentName);
				if(Component != nullptr)
					FetchedComponentsWithNoKnockback.Add(Component);
			}
		}
	}

	bool ShouldBeKnockedback(UPrimitiveComponent ComponentCollidedWith)
	{
		if(!bSpecifyComponentsForNoKnockback)
			return false;

		if(FetchedComponentsWithNoKnockback.Contains(ComponentCollidedWith))
			return false;

		return true;
	}

#if EDITOR
	UFUNCTION()
	private TArray<FName> GetComponentNames() const
	{
		AActor ActorOwner = Owner;
		UObject _Outer = Outer;
		while(ActorOwner == nullptr && _Outer != nullptr)
		{
			ActorOwner = Cast<AActor>(_Outer);
			if(ActorOwner != nullptr)
				break;

			auto BlueprintGeneratedClass = Cast<UBlueprintGeneratedClass>(_Outer);
			if(BlueprintGeneratedClass != nullptr)
			{
				ActorOwner = Cast<AActor>(BlueprintGeneratedClass.DefaultObject);
				if(ActorOwner != nullptr)
					break;
			}

			_Outer = _Outer.Outer;
		}
		
		if(ActorOwner == nullptr)
			return TArray<FName>();

		return Editor::GetAllEditorComponentNamesOfClass(ActorOwner, UPrimitiveComponent);
	}
#endif
};